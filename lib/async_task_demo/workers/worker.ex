defmodule AsyncTaskDemo.Workers.Worker do
  @moduledoc """
  Module implements task execution

  In future, add Postgres Pub/Sub as it is done in Oban
  listen when new task with :new status inserted
  """

  use GenServer
  import Ecto.Query

  alias AsyncTaskDemo.Repo
  alias AsyncTaskDemo.Tasks
  alias AsyncTaskDemo.Tasks.Performer
  alias AsyncTaskDemo.Tasks.Task

  require Logger

  @timeout_milliseconds Application.compile_env(:async_task_demo, :timeout_milliseconds, 10_000)

  @spec enqueue_task(Task.priority()) :: {:ok, :empty_queue | :executed} | {:error, :failed}
  def enqueue_task(priority, name \\ nil) do
    Repo.transaction(fn ->
      with {:ok, task} <- get_task_to_execute(priority),
           Logger.info("Process #{name} enqueued task #{task.id}"),
           {:ok, task} <- Tasks.lock(task),
           {:ok, _task} <- execute_task(task) do
        Logger.info("Process #{name} completed task #{task.id}")
        :executed
      else
        {:error, :no_matching_task} ->
          :empty_queue

        _error ->
          Repo.rollback(:failed)
      end
    end)
  end

  @spec execute_task(Task.t()) :: {:ok, Task.t()} | {:error, Ecto.Changeset.t()}
  def execute_task(%Task{} = task) do
    Logger.metadata(
      task_id: task.id,
      task_priority: task.priority,
      task_type: task.type,
      task_attempt: task.attempt
    )

    perform_result =
      try do
        Performer.run(task)
      rescue
        e in RuntimeError ->
          {:error, e.message}
      end

    case perform_result do
      {:ok, _} ->
        Tasks.complete(task)

      :ok ->
        Tasks.complete(task)

      error ->
        task
        |> Tasks.mark_failed()
        |> then(fn
          {:ok, task} ->
            attempts_left = task.max_attempts - task.attempt

            Logger.error("Failed to perform task, #{attempts_left} attempts left",
              error: inspect(error)
            )

            {:ok, task}

          {:error, _} = error ->
            # never occurs, mark_failed have valid changest and called in transaction (no stale error)
            error
        end)
    end
  end

  @spec get_task_to_execute(Task.priority()) :: {:ok, Task.t()} | {:error, :no_matching_task}
  def get_task_to_execute(priority) do
    task =
      Task
      |> where([t], t.state == :new)
      |> where([t], t.priority == ^priority)
      |> where([t], t.attempt == 0 or t.updated_at < ago(@timeout_milliseconds, "millisecond"))
      |> order_by([t], [t.attempt, t.updated_at])
      |> limit(1)
      |> lock("FOR UPDATE")
      |> Repo.one()

    if task do
      {:ok, task}
    else
      {:error, :no_matching_task}
    end
  end

  @spec worker_name(Task.priority(), non_neg_integer()) :: atom()
  def worker_name(priority, number), do: String.to_atom("#{priority}_#{number}")

  def start_link(%{priority: priority, number: number}) do
    name = worker_name(priority, number)
    state = %{priority: priority, number: number, name: name}

    with {:ok, pid} <- GenServer.start_link(__MODULE__, state, name: name) do
      # Queues by priorities
      Logger.info("Worker to execute tasks with priority #{priority} created",
        queue: priority,
        worker_name: name
      )

      {:ok, pid}
    end
  end

  ###########################################################################
  # GenServer callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_info(:enqueue, %{name: name, priority: priority} = state) do
    case enqueue_task(priority, state.name) do
      {:ok, :empty_queue} ->
        # wait timeout to check queue again (delay for failed tasks, new tasks)
        Process.send_after(self(), :enqueue, @timeout_milliseconds)
        {:noreply, state, :hibernate}

      {:ok, :executed} ->
        # task executed, check for a new task immediately
        send(self(), :enqueue)
        {:noreply, state}

      {:error, _} ->
        Logger.error("Failed to execute #{priority} priority task", worker_name: name)
        # wait timeout to check queue again
        send(self(), :enqueue)
        {:noreply, state, :hibernate}
    end
  end

  def handle_info(info, state) do
    Logger.error("Can't handle info #{inspect(info)}", worker_name: state.name)
    {:noreply, state, :hibernate}
  end
end
