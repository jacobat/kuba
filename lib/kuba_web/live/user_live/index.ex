defmodule KubaWeb.UserLive.Index do
  use KubaWeb, :live_view

  alias Kuba.Accounts
  alias Kuba.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Kuba.PubSub, "test")
    IO.puts "Mounting socket for index live"
    socket = assign(socket, :messages, Chat.messages)
    {:ok, assign(socket, :users, list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    result = socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
    Phoenix.PubSub.broadcast(Kuba.PubSub, "test", "edit:#{id}")
    result
  end

  defp apply_action(socket, :new, _params) do
    Phoenix.PubSub.broadcast(Kuba.PubSub, "test", "new")
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)

    {:noreply, assign(socket, :users, list_users())}
  end

  def handle_info(state, socket) do
    messages = Chat.messages
    IO.puts "HANDLE BROADCAST FOR [#{state}]: #{IO.inspect(messages)}"
    {:noreply, assign(socket, :messages, messages)}
  end

  defp list_users do
    Accounts.list_users()
  end
end
