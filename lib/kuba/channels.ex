defmodule Kuba.Channels do
  require Logger
  alias KubaEngine.User

  def start_channel(name) do
    if KubaEngine.ChannelServer.exist?(name) do
      Logger.debug "Channel #{name} exists"
    else
      Logger.debug("Kuba.Channels.start_channel Channel #{name} starting")
      KubaEngine.ChannelSupervisor.start_channel(name)
      Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channels", {:new_channel, name})
    end
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Kuba.PubSub, "channels")
  end

  def join(name, user = %User{}) do
    Logger.debug("#{user.nick} joining #{name}")
    start_channel(name)
    unless KubaEngine.ChannelServer.member?(name, user) do
      KubaEngine.ChannelServer.join(name, user)
      Phoenix.PubSub.subscribe(Kuba.PubSub, "channel:#{name}")
      Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:join, user})
    end
  end

  def leave(name, user = %User{}) do
    Logger.debug "#{user.nick} left #{name}"
    KubaEngine.ChannelServer.leave(name, user)
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:leave, user})
    Phoenix.PubSub.unsubscribe(Kuba.PubSub, "channel:#{name}")
  end

  def list do
    KubaEngine.ChannelSupervisor.names()
  end

  def logoff(user = %User{}) do
    list() |> Enum.map(fn channel -> leave(channel, user) end)
  end

  def speak(name, user, message) do
    KubaEngine.ChannelServer.speak(name, KubaEngine.Message.new(message, user))
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:speak, message})
  end
end
