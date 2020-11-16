defmodule Kuba.Channels do
  def start_channel(name) do
    IO.puts "Channel #{name} starting"
    KubaEngine.Channel.start_link(name)
  end

  def join(name, nick) do
    KubaEngine.Channel.join(name, nick)
    Phoenix.PubSub.subscribe(Kuba.PubSub, "channel:Lobby")
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:join, nick})
  end

  def speak(name, nick, message) do
    KubaEngine.Channel.speak(name, KubaEngine.Message.new(message, nick))
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:#{name}", {:speak, message})
  end
end
