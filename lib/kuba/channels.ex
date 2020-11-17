defmodule Kuba.Channels do
  def start_channel(name) do
    IO.puts "Channel #{name} starting"
    KubaEngine.Channel.start_link(name)
  end

  def join(name, nick) do
    IO.puts "#{nick} joining #{name}"
    start_channel(name)
    KubaEngine.Channel.join(name, nick)
    Phoenix.PubSub.subscribe(Kuba.PubSub, "channel:Lobby")
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:join, nick})
  end

  def leave(name, nick) do
    IO.puts "#{nick} left #{name}"
    KubaEngine.Channel.leave(name, nick)
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:leave, nick})
    Phoenix.PubSub.unsubscribe(Kuba.PubSub, "channel:Lobby")
  end


  def speak(name, nick, message) do
    KubaEngine.Channel.speak(name, KubaEngine.Message.new(message, nick))
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:speak, message})
  end
end
