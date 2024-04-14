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

  def create(
        %Plug.Conn{
          body_params: %TaskParams{
            type: type,
            priority: priority,
            data: data,
            max_attempts: max_attempts
          }
        } = conn,
        _
      ) do
    with {:ok, task} <-
           AsyncTaskDemo.Tasks.create(%{
             type: type,
             priority: priority,
             data: data,
             max_attempts: max_attempts
           }) do
      conn
      |> put_status(:created)
      |> json(task)
    end
  end
end
