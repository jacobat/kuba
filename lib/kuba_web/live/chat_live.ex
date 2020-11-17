defmodule KubaWeb.ChatLive do
  use KubaWeb, :live_view

  alias KubaEngine.{Message,SystemMessage}

  @impl true
  def mount(_params, session, socket) do
    nick = session["nick"]

    IO.inspect session
    if connected?(socket) do
      KubaWeb.ChatLiveMonitor.monitor(ChatLiveMonitor, self(), __MODULE__, %{id: socket.id, nick: nick})
      Kuba.Channels.join("Lobby", nick)
    end
    {:ok, assign(socket, nick: nick, channel: channel, chat: changeset, messages: messages)}
  end

  def unmount(%{id: id, nick: nick}, _reason) do
    Kuba.Channels.leave("Lobby", nick)
    IO.puts("view #{id} unmounted")
    :ok
  end

  def format_message(%Message{author: author, datetime: datetime, body: body}) do
    "#{Calendar.strftime(datetime, "%H:%M")} #{author}: #{body}"
  end

  def format_message(%SystemMessage{datetime: datetime, body: body}) do
    "#{Calendar.strftime(datetime, "%H:%M")}: #{body}"
  end

  def handle_event("save", %{"chat" => %{"message" => "/join " <> name}}, socket) do
    Kuba.Channels.join(name, socket.assigns.nick)
    {
      :noreply,
      assign(socket, :chat, changeset())
      |> assign(:messages, messages)
    }
  end

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
    new_socket = assign(socket, channel: channel, messages: messages)
    {:noreply, new_socket}
  end

  def handle_info({:leave, nick}, socket) do
    IO.puts "#{inspect self()} received leave from #{nick}"
    new_socket = assign(socket, channel: channel, messages: messages)
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

