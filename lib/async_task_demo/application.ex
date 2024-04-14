defmodule AsyncTaskDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias AsyncTaskDemo.Workers.LockManager
  alias AsyncTaskDemo.Workers.Worker
  alias AsyncTaskDemo.Workers.WorkerManager

  @app :async_task_demo

  @impl true
  def start(_type, _args) do
    children =
      [
        AsyncTaskDemoWeb.Telemetry,
        AsyncTaskDemo.Repo,
        {DNSCluster, query: Application.get_env(:async_task_demo, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: AsyncTaskDemo.PubSub},
        AsyncTaskDemoWeb.Endpoint
      ] ++ [LockManager, WorkerManager | taks_workers_pool()]

    opts = [strategy: :one_for_one, name: AsyncTaskDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @priorities [:high, :normal, :low]
  defp taks_workers_pool do
    config_queues_concurrency = Application.get_env(@app, :queues_concurrency)
    default_queues_concurrency = [high: 10, normal: 5, low: 1]

    queues_concurrency =
      default_queues_concurrency
      |> Keyword.merge(config_queues_concurrency)
      |> Keyword.take(@priorities)

    Enum.reduce(queues_concurrency, [], fn {queue, workers_number}, children_spec ->
      workers =
        Enum.map(1..workers_number, fn number ->
          %{
            id: {queue, number, Worker},
            start: {Worker, :start_link, [%{queue: queue, number: number}]}
          }
        end)

      children_spec ++ workers
    end)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AsyncTaskDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
