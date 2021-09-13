defmodule KubaWeb.ChatLive do
  require Logger
  use KubaWeb, :live_view

  alias KubaEngine.{Message, SystemMessage, User}

  @impl true
  def mount(_params, session, socket) do
    user = User.new(session["nick"])

    Logger.debug(inspect(session))

    if connected?(socket) do
      KubaWeb.ChatLiveMonitor.monitor(ChatLiveMonitor, self(), __MODULE__, %{
        id: socket.id,
        user: user
      })

      Kuba.Channels.subscribe()
      Kuba.Channels.join("Lobby", user)
    end

    new_socket =
      socket
      |> assign(
        user: user,
        channel: channel("Lobby"),
        channels: channels(),
        chat: changeset()
      )

    {
      :ok,
      assign(new_socket, messages: messages(new_socket))
    }
  end

  def unmount(%{id: id, user: user}, _reason) do
    Kuba.Channels.logoff(user)
    Logger.debug("view #{id} unmounted")
    :ok
  end

  def format_message(user = %User{}, %Message{author: author, datetime: datetime, body: body}) do
    if user == author do
      content_tag(
        :span,
        [
          format_time(datetime),
          content_tag(:span, " #{author.nick}:", class: "text-blue-600"),
          " ",
          body
        ],
        class: "font-mono"
      )
    else
      content_tag(
        :span,
        [
          format_time(datetime),
          " #{author.nick}: #{body}"
        ],
        class: "font-mono"
      )
    end
  end

  def format_message(_user, %SystemMessage{datetime: datetime, body: body}) do
    [content_tag(:span, "#{format_time(datetime)} #{body}", class: "font-mono")]
  end

  def format_time(datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Copenhagen")
    |> Calendar.strftime("%H:%M")
  end

  @impl true
  def handle_event("save", %{"chat" => %{"message" => "/join " <> name}}, socket),
    do: join(name, socket)

  @impl true
  def handle_event("join", %{"name" => name}, socket), do: join(name, socket)

  @impl true
  def handle_event("join-new", _, socket),
    do: {:noreply, assign(socket, :chat, changeset("/join "))}

  @impl true
  def handle_event("save", %{"chat" => %{"message" => message}}, socket) do
    Kuba.Channels.speak(current_channel_name(socket), socket.assigns.user, message)

    {
      :noreply,
      assign(socket, :chat, changeset())
      |> assign(:messages, messages(socket))
    }
  end

  @impl true
  def handle_event("change", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, :chat, changeset(message))}
  end

  @impl true
  def handle_info({:new_channel, name}, socket) do
    new_socket =
      socket
      |> assign(channels: channels())

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:speak, message}, socket) do
    Logger.debug("#{inspect(self())} received #{message}")
    new_socket = assign(socket, messages: messages(socket))
    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:join, user}, socket) do
    Logger.debug("#{inspect(self())} received join from #{user.nick}")

    new_socket =
      socket
      |> assign(channel: current_channel(socket))
      |> assign(messages: messages(socket))
      |> assign(channels: channels())

    {:noreply, new_socket}
  end

  def handle_info({:leave, user}, socket) do
    Logger.debug("#{inspect(self())} received leave from #{user.nick}")
    new_socket = assign(socket, channel: current_channel(socket), messages: messages(socket))
    {:noreply, new_socket}
  end

  def join(name, socket) do
    Kuba.Channels.join(name, socket.assigns.user)

    new_socket =
      socket
      |> assign(:chat, changeset())
      |> assign(:channel, channel(name))
      |> assign(channels: channels())

    {
      :noreply,
      assign(new_socket, :messages, messages(new_socket))
    }
  end

  defp current_channel(socket) do
    current_channel_name(socket)
    |> channel()
  end

  defp current_channel_name(socket) do
    socket.assigns.channel.name
  end

  defp channel(name) do
    KubaEngine.Channel.channel_for(name)
  end

  defp channels do
    Kuba.Channels.list()
  end

  defp messages(socket) do
    Logger.debug("#{inspect(self())} Getting messages on #{current_channel_name(socket)}")
    KubaEngine.Channel.messages_for(current_channel_name(socket)) |> Enum.take(20)
  end

  defp changeset() do
    data = %{message: ""}
    types = %{message: :string}
    Ecto.Changeset.cast({data, types}, %{message: ""}, [:message])
  end

  defp changeset(message) do
    data = %{message: ""}
    types = %{message: :string}
    Ecto.Changeset.cast({data, types}, %{message: message}, [:message])
  end
end
