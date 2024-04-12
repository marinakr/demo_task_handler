defmodule AsyncTaskDemo.Tasks.Task do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, except: [:__meta__, :__struct__]}

  schema "tasks" do
    field :type
    field :priority, Ecto.Enum, values: [high: 1, normal: 2, low: 3], default: :normal
    field :data, :map

    timestamps()
  end

  @fields [:type, :priority, :data]
  @required_fields [:type, :priority]

  def changeset(%__MODULE__{} = task, attrs) do
    task
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
