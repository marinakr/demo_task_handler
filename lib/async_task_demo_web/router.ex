defmodule AsyncTaskDemoWeb.Router do
  use AsyncTaskDemoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: AsyncTaskDemo.ApiSpec
  end

  scope "/api" do
    pipe_through :api

    # consider to add [:index, :show] later
    resources "/users", AsyncTaskDemoWeb.TaskController, only: [:create]

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end
end
