defmodule AsyncTaskDemo.ApplicatioTest do
  use AsyncTaskDemo.DataCase, async: true

  @app :async_task_demo

  test "minimum workers pool created" do
    for queue <- AsyncTaskDemo.Tasks.priorities() do
      assert assert_worker_alive("#{queue}_1")
    end
  end

  test "tasks workers pool created by config" do
    config_priority_queues = Application.get_env(@app, :priority_queues)

    for queue <- AsyncTaskDemo.Tasks.priorities() do
      queue_concurrency = config_priority_queues[queue]

      if queue_concurrency do
        for worker_number <- 1..queue_concurrency do
          assert_worker_alive("#{queue}_#{worker_number}")
        end
      end
    end
  end

  #############################################################################
  ## Internal

  defp assert_worker_alive(worker_name) do
    worker_name
    |> String.to_existing_atom()
    |> Process.whereis()
    |> Process.alive?()
  end
end
