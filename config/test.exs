import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :async_task_demo, AsyncTaskDemo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "async_task_demo_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :async_task_demo, AsyncTaskDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rRYUKQAxaxsg7YYW/JLir5WD16QG4QpaAV8ikPJSnhybK7wmea9hP8r9tzUogOJw",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Max concurrency limiting
config :async_task_demo,
  environment: :test,
  timeout_milliseconds: 10,
  priority_queues: [
    normal: 10,
    low: 1
  ]
