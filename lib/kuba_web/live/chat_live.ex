defmodule KubaWeb.ChatLive do
  use KubaWeb, :live_view

  alias KubaEngine.{Message,SystemMessage,User}

  @impl true
  def mount(_params, session, socket) do
    user = User.new(session["nick"])

    IO.inspect session
    if connected?(socket) do
      KubaWeb.ChatLiveMonitor.monitor(ChatLiveMonitor, self(), __MODULE__, %{id: socket.id, user: user})
      Kuba.Channels.join("Lobby", user)
    end
    new_socket = socket
                 |> assign(user: user,
                   channel: channel("Lobby"),
                   channels: channels,
                   chat: changeset)
    {
      :ok,
      assign(new_socket, messages: messages(new_socket))
    }
  end

  def unmount(%{id: id, user: user}, _reason) do
    Kuba.Channels.leave("Lobby", user)
    IO.puts("view #{id} unmounted")
    :ok
  end

  def format_message(%Message{author: author, datetime: datetime, body: body}) do
    "#{Calendar.strftime(datetime, "%H:%M")} #{author.nick}: #{body}"
  end

  def format_message(%SystemMessage{datetime: datetime, body: body}) do
    "#{Calendar.strftime(datetime, "%H:%M")}: #{body}"
  end

  def handle_event("save", %{"chat" => %{"message" => "/join " <> name}}, socket) do
    Kuba.Channels.join(name, socket.assigns.user)
    new_socket = assign(socket, :chat, changeset())
    |> assign(:channel, channel(name))
    {
      :noreply,
      assign(new_socket, :messages, messages(new_socket))
    }
  end

  def handle_event("save", %{"chat" => %{"message" => message}}, socket) do
    Kuba.Channels.speak(current_channel_name(socket), socket.assigns.user, message)
    {
      :noreply,
      assign(socket, :chat, changeset())
      |> assign(:messages, messages(socket))
    }
  end

  def handle_event("change", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, :chat, changeset(message))}
  end

  def handle_info({:speak, message}, socket) do
    IO.puts "#{inspect self()} received #{message}"
    new_socket = assign(socket, messages: messages(socket))
    {:noreply, new_socket}
  end

  def handle_info({:join, user}, socket) do
    IO.puts "#{inspect self()} received join from #{user.nick}"
    new_socket = assign(socket, channel: current_channel(socket), messages: messages(socket))
    {:noreply, new_socket}
  end

  def handle_info({:leave, user}, socket) do
    IO.puts "#{inspect self()} received leave from #{user.nick}"
    new_socket = assign(socket, channel: current_channel(socket), messages: messages(socket))
    {:noreply, new_socket}
  end

  defp current_channel(socket) do
    socket.assigns.channel
  end

  defp current_channel_name(socket) do
    current_channel(socket).name
  end


  defp channel(name) do
    KubaEngine.Channel.channel_for(name)
  end

  defp channels do
    Kuba.Channels.list
  end

  defp messages(socket) do
    IO.puts "Getting messages on #{current_channel_name(socket)}"
    KubaEngine.Channel.messages_for(current_channel_name(socket)) |> Enum.take(20)
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

