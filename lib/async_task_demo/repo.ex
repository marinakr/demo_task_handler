defmodule AsyncTaskDemo.Repo do
  use Ecto.Repo,
    otp_app: :async_task_demo,
    adapter: Ecto.Adapters.Postgres
end
