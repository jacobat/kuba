defmodule KubaWeb.SignInController do
  use KubaWeb, :controller

  def show(conn, _params) do
    render(conn, "show.html", changeset: changeset())
  end

  def create(conn, params) do
    conn
    |> put_session(:nick, params["nick"])
    |> redirect(to: "/chat")
  end

  defp changeset() do
    data = %{name: ""}
    types = %{name: :string}
    Ecto.Changeset.cast({data, types}, %{}, [])
  end
end
