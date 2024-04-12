defmodule AsyncTaskDemo.Schemas do
  alias OpenApiSpex.Schema

  defmodule TaskPriority do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Task Priority",
      description: "Defines priority of task",
      type: :string,
      enum: ["high", "normal", "low"]
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
        data: TaskData
      },
      required: [:type, :data],
      example: %{
        "priority" => "high",
        "type" => "report",
        "data" => %{"timeline" => "yaer", "department" => "R&D"}
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
          data: TaskData
        }
      },
      example: %{
        "data" => %{
          "id" => 1,
          "priority" => "high",
          "type" => "report",
          "data" => %{"timeline" => "yaer", "department" => "R&D"}
        }
      }
    )
  end
end
