defmodule Kuba.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Kuba.Repo,
      # Start the Telemetry supervisor
      KubaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Kuba.PubSub},
      # Start the Endpoint (http/https)
      KubaWeb.Endpoint,
      # Start a worker by calling: Kuba.Worker.start_link(arg)
      # {Kuba.Worker, arg}
      {Chat, []},
      {KubaWeb.ChatLiveMonitor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kuba.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    KubaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
