defmodule Kuba.Repo do
  use Ecto.Repo,
    otp_app: :kuba,
    adapter: Ecto.Adapters.Postgres
end
