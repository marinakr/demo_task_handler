defmodule AsyncTaskDemoWeb.TaskController do
  use AsyncTaskDemoWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias AsyncTaskDemo.Schemas.TaskParams
  alias AsyncTaskDemo.Schemas.TaskResponse

  plug OpenApiSpex.Plug.CastAndValidate

  tags(["tasks"])

  operation(:create,
    summary: "Enqueue task",
    parameters: [],
    request_body: {"Task params", "application/json", TaskParams},
    responses: %{
      201 => {"Task response", "application/json", TaskResponse},
      422 => OpenApiSpex.JsonErrorResponse.response()
    }
  )

  def create(%Plug.Conn{body_params: body_params} = conn, _) do
    # body_params is request body params validated and casted to TaskParams schema
    attrs = Map.take(body_params, ~w(type priority data max_attempts)a)

    with {:ok, task} <- AsyncTaskDemo.Tasks.create(attrs) do
      conn
      |> put_status(:created)
      |> json(task)
    end
  end
end
