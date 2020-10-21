# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :kuba,
  ecto_repos: [Kuba.Repo]

# Configures the endpoint
config :kuba, KubaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jjla+Hyou6xe6WuYL4M8+qHtFEMP3Qvm2ExxVUNQA27vnMAHxQo+sleScTRqVXKM",
  render_errors: [view: KubaWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Kuba.PubSub,
  live_view: [signing_salt: "FakMY5TJ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
