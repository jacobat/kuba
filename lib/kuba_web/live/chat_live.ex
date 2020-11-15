defmodule KubaWeb.ChatLive do
  use KubaWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    nick = session["nick"]
    KubaEngine.Channel.start_link("Lobby")
    Phoenix.PubSub.subscribe(Kuba.PubSub, "channel:Lobby")

    IO.inspect session
    if connected?(socket) do
      KubaEngine.Channel.join("Lobby", nick)
      {:ok, assign(socket, nick: nick, channel: channel, chat: changeset, messages: messages)}
    else
      {:ok, assign(socket, channel: channel, chat: changeset, messages: messages)}
    end
  end

  @impl true
  def handle_event("save", %{"chat" => %{"message" => message}}, socket) do
    KubaEngine.Channel.speak("Lobby", KubaEngine.Message.new(message, socket.assigns.nick))
    Phoenix.PubSub.broadcast_from(Kuba.PubSub, self(), "channel:Lobby", {:speak, message})
    {
      :noreply,
      assign(socket, :chat, changeset())
      |> assign(:messages, messages)
    }
  end

  def handle_event("change", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, :chat, changeset(message))}
  end

  def handle_info({:speak, message}, socket) do
    IO.puts "#{inspect self()} received #{message}"
    new_socket = assign(socket, messages: messages)
    {:noreply, new_socket}
  end


  defp channel do
    KubaEngine.Channel.channel_for("Lobby")
  end

  defp messages do
    KubaEngine.Channel.messages_for("Lobby") |> Enum.take(20)
  end

  defp changeset() do
    data = %{message: ""}
    types = %{message: :string}
    Ecto.Changeset.cast({data, types}, %{ message: ""}, [:message])
  end

  defp changeset(message) do
    data = %{message: ""}
    types = %{message: :string}
    Ecto.Changeset.cast({data, types}, %{ message: message}, [:message])
  end
end

