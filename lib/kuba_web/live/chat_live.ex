defmodule KubaWeb.ChatLive do
  use KubaWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    nick = session["nick"]

    IO.inspect session
    if connected?(socket) do
      Kuba.Channels.join("Lobby", nick)
      {:ok, assign(socket, nick: nick, channel: channel, chat: changeset, messages: messages)}
    else
      {:ok, assign(socket, channel: channel, chat: changeset, messages: messages)}
    end
  end

  @impl true
  def handle_event("save", %{"chat" => %{"message" => message}}, socket) do
    Kuba.Channels.speak("Lobby", socket.assigns.nick, message)
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

  def handle_info({:join, nick}, socket) do
    IO.puts "#{inspect self()} received join from #{nick}"
    new_socket = assign(socket, channel: channel)
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

