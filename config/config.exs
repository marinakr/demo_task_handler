# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :async_task_demo,
  ecto_repos: [AsyncTaskDemo.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :async_task_demo, AsyncTaskDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: AsyncTaskDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AsyncTaskDemo.PubSub,
  live_view: [signing_salt: "8R6NqlvB"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Max concurrency limiting
config :async_task_demo,
  max_attempts: 5,
  queues_concurrency: [
    high: 10,
    normal: 5,
    low: 1
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
