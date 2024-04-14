defmodule AsyncTaskDemo.Tasks do
  @moduledoc "Module provides operations with Task entity"

  alias AsyncTaskDemo.Repo
  alias AsyncTaskDemo.Tasks.Task

  @type attrs :: %{
          required(:type) => binary(),
          optional(:priority) => binary(),
          optional(:data) => map(),
          optional(:max_attempts) => integer
        }

  def priorities, do: Ecto.Enum.values(Task, :priority)

  @spec create(attrs()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
    |> tap(fn
      {:ok, task} ->
        # Consider to use Postgres Pub/Sub with `pg_notify` later
        # notify random worker
        {:ok, task}

      {:error, changeset} ->
        {:error, changeset}
    end)
  end

  @spec lock(Task.t()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def lock(taks) do
    taks
    |> Task.lock_changeset()
    |> Repo.update()
  end

  @spec complete(Task.t()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def complete(task) do
    task
    |> Task.success_changeset()
    |> Repo.update()
  end

  @spec mark_failed(Task.t()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def mark_failed(task) do
    task
    |> Task.error_changeset()
    |> Repo.update()
  end
end
