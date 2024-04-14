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
        %Plug.Conn{body_params: %TaskParams{type: type, priority: priority, data: data}} = conn,
        _
      ) do
    # open_api_spex validates input, so &String.to_existing_atom/1 will not fail, enum defined
    priority = priority && String.to_existing_atom(priority)

    with {:ok, task} <-
           AsyncTaskDemo.Tasks.create(%{
             type: type,
             priority: priority,
             data: data
           }) do
      conn
      |> put_status(:created)
      |> json(task)
    end
  end
end
