defmodule AsyncTaskDemo.Schemas do
  alias OpenApiSpex.Schema

  defmodule TaskAttempt do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Attempt number",
      type: :integer,
      format: :int32,
      description: "number of attempt to execute task is done by now",
      default: 0,
      minimum: 0
    })
  end

  defmodule TaskMaxAttempts do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Max attempts",
      type: :integer,
      format: :int32,
      description: "number of times task executed if attempt to execute task fails",
      minimum: 0
    })
  end

  defmodule TaskState do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "State of task",
      description: "Show on whant execution state task is now",
      type: :string,
      enum: ["new", "executing", "completed", "failed"]
    })
  end

  defmodule TaskPriority do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Task Priority",
      description: "Defines priority of task",
      type: :string,
      enum: ["high", "normal", "low"],
      default: "normal"
    })
  end

  defmodule TaskType do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :string,
      title: "Task Type",
      description: "Type of task",
      pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/
    })
  end

  defmodule TaskData do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Task Data",
      type: :object,
      description: "Task details"
    })
  end

  defmodule DateTime do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :string,
      format: :"date-time"
    })
  end

  defmodule TaskParams do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      # The title is optional. It defaults to the last section of the module name.
      # So the derived title for MyApp.User is "User".
      title: "TaskParams",
      description: "A task for the app to enqueue",
      type: :object,
      properties: %{
        priority: TaskPriority,
        type: TaskType,
        data: TaskData,
        max_attempts: TaskMaxAttempts
      },
      required: [:type, :data],
      example: %{
        "priority" => "high",
        "type" => "report",
        "data" => %{"timeline" => "year", "department" => "R&D"}
      }
    })
  end

  defmodule TaskResponse do
    require OpenApiSpex

    OpenApiSpex.schema(
      %{
        title: "TaskResponse",
        description: "Response schema for single task",
        type: :object,
        properties: %{
          id: %Schema{type: :integer, minimum: 1},
          priority: TaskPriority,
          type: TaskType,
          data: TaskData,
          attempt: TaskAttempt,
          max_attempts: TaskMaxAttempts,
          state: TaskState,
          inserted_at: DateTime,
          updated_at: DateTime
        }
      },
      example: %{
        "data" => %{
          "id" => 1,
          "priority" => "high",
          "type" => "report",
          "data" => %{"timeline" => "year", "department" => "R&D"},
          "attempt" => 2,
          "max_attempts" => 5,
          "state" => "new"
        }
      }
    )
  end
end
