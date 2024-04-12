defmodule AsyncTaskDemo.Tasks do
  @moduledoc "Module provides operations with Task entity"

  alias AsyncTaskDemo.Tasks.Task
  alias AsyncTaskDemo.Repo

  @type attrs :: %{
          required(:type) => binary(),
          optional(:priority) => binary(),
          optional(:data) => map()
        }

  @spec create(attrs()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end
end
