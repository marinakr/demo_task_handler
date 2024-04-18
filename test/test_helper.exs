Mimic.copy(HTTPoison)
{:ok, _} = Application.ensure_all_started(:mimic)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(AsyncTaskDemo.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
