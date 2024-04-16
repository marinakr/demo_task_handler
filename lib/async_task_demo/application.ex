defmodule AsyncTaskDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias AsyncTaskDemo.Tasks.Task
  alias AsyncTaskDemo.Workers.Worker

  @app :async_task_demo
  @priorities AsyncTaskDemo.Tasks.priorities()

  @type worker_name :: atom()
  @type env :: nil | :test | :dev | :prod | term()

  @impl true
  def start(_type, _args) do
    children =
      [
        AsyncTaskDemoWeb.Telemetry,
        AsyncTaskDemo.Repo,
        {DNSCluster, query: Application.get_env(:async_task_demo, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: AsyncTaskDemo.PubSub},
        AsyncTaskDemoWeb.Endpoint
      ] ++ taks_workers_pool()

    opts = [strategy: :one_for_one, name: AsyncTaskDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AsyncTaskDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @impl true
  def start_phase(:check_tasks, :normal, _) do
    environment = Application.get_env(@app, :environment)
    enqueue_tasks(environment)
    :ok
  end

  @spec notify_random_worker(Task.priority()) :: :ok
  @spec notify_random_worker(Task.priority(), env) :: :ok

  def notify_random_worker(priority) do
    environment = Application.get_env(@app, :environment)
    notify_random_worker(priority, environment)
  end

  def notify_random_worker(_priority, :test), do: :ok

  def notify_random_worker(priority, _env) do
    random_worker = get_random_worker(priority)
    send(random_worker, :enqueue)
    :ok
  end

  #############################################################################
  ## Internal
  @spec taks_workers_pool :: [Supervisor.child_spec()]
  defp taks_workers_pool do
    priority_queues = get_priority_queues()

    Enum.reduce(priority_queues, [], fn {priority, workers_number}, children_spec ->
      workers =
        Enum.map(1..workers_number, fn number ->
          %{
            id: {priority, number, Worker},
            start: {Worker, :start_link, [%{priority: priority, number: number}]}
          }
        end)

      children_spec ++ workers
    end)
  end

  @spec get_random_worker(Task.priority()) :: worker_name()
  defp get_random_worker(priority) do
    get_random_worker_alive(get_priority_worker_names()[priority])
  end

  @spec get_random_worker_alive([worker_name()]) :: nil | worker_name()
  # normally any worker is alive
  # check if randomly selected worker are restarting at very same moment

  defp get_random_worker_alive([]), do: nil

  defp get_random_worker_alive(priority_queue) do
    worker = Enum.random(priority_queue)

    if Process.alive?(worker) do
      worker
    else
      get_random_worker_alive(priority_queue -- [worker])
    end
  end

  @spec enqueue_tasks(env()) :: :ok | :ignore
  defp enqueue_tasks(:test), do: :ignore

  defp enqueue_tasks(_env) do
    get_priority_worker_names()
    |> Map.values()
    |> List.flatten()
    |> Enum.each(&send(&1, :enqueue))
  end

  @spec get_priority_worker_names :: %{
          required(:high) => [worker_name()],
          required(:normal) => [worker_name()],
          required(:low) => [worker_name()]
        }
  defp get_priority_worker_names do
    priority_queues = get_priority_queues()

    Enum.reduce(priority_queues, %{}, fn {priority, workers_number}, acc ->
      priority_workers = Enum.map(1..workers_number, &Worker.worker_name(priority, &1))
      Map.put(acc, priority, priority_workers)
    end)
  end

  @spec get_priority_queues :: Keyword.t()
  defp get_priority_queues do
    config_priority_queues = Application.get_env(@app, :priority_queues)
    # Ensure each priority has at least one worker
    minimum_priority_queues = Enum.map(@priorities, &{&1, 1})

    minimum_priority_queues
    |> Keyword.merge(config_priority_queues)
    |> Keyword.take(@priorities)
  end
end
