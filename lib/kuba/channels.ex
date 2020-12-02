defmodule Kuba.Channels do
  alias KubaEngine.User

  def start_channel(name) do
    if KubaEngine.Channel.exist?(name) do
      IO.puts "Channel #{name} exists"
    else
      IO.puts "Kuba.Channels.start_channel Channel #{name} starting"
      KubaEngine.ChannelSupervisor.start_channel(name)
    end
  end

  def join(name, user = %User{}) do
    IO.puts "#{user.nick} joining #{name}"
    start_channel(name)
    KubaEngine.Channel.join(name, user)
    Phoenix.PubSub.subscribe(Kuba.PubSub, "channel:#{name}")
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:join, user})
  end

  def leave(name, user = %User{}) do
    IO.puts "#{user.nick} left #{name}"
    KubaEngine.Channel.leave(name, user)
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:leave, user})
    Phoenix.PubSub.unsubscribe(Kuba.PubSub, "channel:#{name}")
  end

  def list do
    KubaEngine.ChannelSupervisor.names
    |> Enum.map(&KubaEngine.Channel.channel_for/1)
  end


  def logoff(user = %User{}) do
    list() |> Enum.map(fn channel -> leave(channel.name, user) end)
  end

  def speak(name, nick, message) do
    KubaEngine.Channel.speak(name, KubaEngine.Message.new(message, nick))
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:speak, message})
  end
end
