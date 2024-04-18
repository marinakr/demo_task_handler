defmodule AsyncTaskDemo.Tasks.Task do
  @moduledoc "Shcema for db `task` entity"
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}
  @type id :: non_neg_integer()
  @type priority :: :high | :normal | :low

  @derive {Jason.Encoder, except: [:__meta__, :__struct__]}

  @app :async_task_demo

  schema "tasks" do
    field :type
    field :priority, Ecto.Enum, values: [high: 1, normal: 2, low: 3], default: :normal
    field :data, :map

    field :state, Ecto.Enum, values: [:new, :executing, :completed, :failed]
    field :attempt, :integer, default: 0
    field :max_attempts, :integer

    timestamps()
  end

  @fields [:type, :priority, :data, :state, :attempt, :max_attempts]
  @required_fields [:type, :priority, :state, :max_attempts]

  def changeset(%__MODULE__{} = task, attrs) do
    task
    |> cast(attrs, @fields)
    |> then(fn changeset ->
      priority = get_field(changeset, :priority) || :normal
      state = get_field(changeset, :state) || :new
      max_attempts = get_field(changeset, :max_attempts) || get_max_attempts()

      changeset
      |> put_change(:priority, priority)
      |> put_change(:state, state)
      |> put_change(:max_attempts, max_attempts)
    end)
    |> validate_required(@required_fields)
  end

  @spec success_changeset(__MODULE__.t()) :: Ecto.Changeset.t()
  def success_changeset(task) do
    change(task, %{attempt: task.attempt + 1, state: :completed})
  end

  @spec lock_changeset(__MODULE__.t()) :: Ecto.Changeset.t()
  def lock_changeset(task) do
    change(task, %{state: :executing})
  end

  @spec error_changeset(__MODULE__.t()) :: Ecto.Changeset.t()
  def error_changeset(task) do
    task
    |> cast(%{attempt: task.attempt + 1}, [:attempt])
    |> then(fn
      %Ecto.Changeset{data: %{max_attempts: max_attempts}, changes: %{attempt: attempt}} =
          changeset
      when attempt < max_attempts ->
        put_change(changeset, :state, :new)

      changeset ->
        put_change(changeset, :state, :failed)
    end)
  end

  #############################################################################
  ## Internal

  defp get_max_attempts do
    Application.get_env(@app, :max_attempts) || 5
  end
end
