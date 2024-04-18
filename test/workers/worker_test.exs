defmodule AsyncTaskDemo.Workers.WorkerTest do
  use AsyncTaskDemo.DataCase, async: true

  import Mimic

  alias AsyncTaskDemo.Repo
  alias AsyncTaskDemo.Tasks.Task
  alias AsyncTaskDemo.Workers.Worker

  @timeout_milliseconds Application.compile_env!(:async_task_demo, :timeout_milliseconds)

  describe "enqueue_task/1" do
    test "queue is empty" do
      insert(:task, priority: :high)
      insert(:task, priority: :low)

      assert {:ok, :empty_queue} = Worker.enqueue_task(:normal)
    end

    test "get task, lock, set perform status for successfully performed jobs" do
      for priority <- AsyncTaskDemo.Tasks.priorities() do
        task = insert(:task, type: "report", priority: priority)

        assert {:ok, :executed} = Worker.enqueue_task(priority)
        assert %Task{state: :completed} = Repo.reload(task)
      end
    end

    test "get task, lock, set perform status for failed jobs" do
      tasks =
        for priority <- AsyncTaskDemo.Tasks.priorities() do
          insert(:task, type: "unknown", priority: priority)
        end

      for task <- tasks do
        for attempt <- 1..task.max_attempts do
          log =
            capture_log(fn ->
              task = Repo.reload(task)
              assert Worker.enqueue_task(task.priority)
            end)

          n = task.max_attempts - attempt
          assert log =~ "Failed to perform task, #{n} attempts left"

          # wait until task can be executed again
          # for test, it is 1 millisecond
          Process.sleep(@timeout_milliseconds)
        end
      end

      for task <- tasks do
        assert %Task{state: :failed} = Repo.reload(task)
      end
    end
  end

  describe "get_task_to_execute/0" do
    test "returns task to execute, order by priority" do
      for priority <- AsyncTaskDemo.Tasks.priorities() do
        insert(:task, priority: priority, attempt: 2)
        %{id: id} = insert(:task, priority: priority)

        assert {:ok, %Task{id: ^id}} = Worker.get_task_to_execute(priority)
      end
    end

    test "returns task to execute, respects updated_at" do
      for priority <- AsyncTaskDemo.Tasks.priorities() do
        # no match, need to wait time between retries
        insert(:task,
          priority: priority,
          attempt: 1,
          updated_at: DateTime.add(DateTime.utc_now(), 60)
        )

        %{id: id} =
          insert(:task,
            priority: priority,
            attempt: 2,
            updated_at: DateTime.add(DateTime.utc_now(), -@timeout_milliseconds * 1000 + 1)
          )

        assert {:ok, %Task{id: ^id}} = Worker.get_task_to_execute(priority)
      end
    end

    test "returns task to execute, respects updated_at and priority in order_by for failed tasks" do
      for priority <- AsyncTaskDemo.Tasks.priorities() do
        insert(:task, priority: priority, attempt: 2)

        %{id: id} =
          insert(:task,
            priority: priority,
            attempt: 2,
            updated_at: DateTime.add(DateTime.utc_now(), -2)
          )

        assert {:ok, %Task{id: ^id}} = Worker.get_task_to_execute(priority)
      end
    end

    test "no tasks to execute" do
      for priority <- AsyncTaskDemo.Tasks.priorities(),
          state <- Ecto.Enum.values(Task, :state) -- [:new] do
        insert(:task, priority: priority, state: state)
        assert {:error, :no_matching_task} = Worker.get_task_to_execute(priority)
      end
    end
  end

  describe "execute_task/1" do
    test "successfully executes task and marks task as completed when `:ok` returned" do
      task = insert(:task, type: "check")
      {:ok, %Task{}} = Worker.execute_task(task)
      assert %Task{state: :completed} = Repo.reload(task)
    end

    test "successfully executes task and marks task as completed when `{:ok, _}` returned" do
      task = insert(:task, type: "report")
      {:ok, %Task{}} = Worker.execute_task(task)
      assert %Task{state: :completed} = Repo.reload(task)
    end

    test "mark attept as used for failed task" do
      task =
        insert(:task,
          attempt: 1,
          type: "email",
          data: %{to: "receiver@mail.com", message: "Hello", topic: "task testing"}
        )

      expect(HTTPoison, :post, fn _, _ ->
        {:error, %HTTPoison.Error{}}
      end)

      log =
        capture_log(fn ->
          {:ok, %Task{attempt: 2}} = Worker.execute_task(task)
        end)

      assert %Task{attempt: 2, state: :new} = Repo.reload(task)
      assert log =~ "Failed to perform task, 3 attempts left"
    end

    test "handles raised error" do
      task = insert(:task, attempt: 2, type: "email", data: %{body: "invalid body"})

      log =
        capture_log(fn ->
          {:ok, %Task{attempt: 3}} = Worker.execute_task(task)
        end)

      assert %Task{attempt: 3, state: :new} = Repo.reload(task)

      assert log =~ "Invalid email data"
      assert log =~ "Failed to perform task, 2 attempts left"
    end

    test "marks job as failed when max attempts is reached" do
      task = insert(:task, attempt: 7, max_attempts: 8, type: "unknown type")

      log =
        capture_log(fn ->
          {:ok, %Task{attempt: 8, state: :failed}} = Worker.execute_task(task)
        end)

      assert %Task{attempt: 8, state: :failed} = Repo.reload(task)
      assert log =~ "Failed to perform task, 0 attempts left"
    end
  end

  describe "handle_info/2" do
    test "no tasks in db for priority, waits timeout" do
      assert {:noreply, _state, :hibernate} =
               Worker.handle_info(:enqueue, %{name: :normal_1, priority: :normal})

      # assert_received does not works for send after
      Process.sleep(@timeout_milliseconds)
      assert_received :enqueue
    end

    test "sends new :enqueue if task was executed" do
      insert(:task, type: "unknown type", priority: :normal)

      log =
        capture_log(fn ->
          assert {:noreply, _state} =
                   Worker.handle_info(:enqueue, %{name: :normal_1, priority: :normal})

          # enqueues new task immediately
          assert_received :enqueue
        end)

      assert log =~ "Failed to perform task, 4 attempts left"
    end

    test "no patternt for received info" do
      log =
        capture_log(fn ->
          assert {:noreply, _state, :hibernate} = Worker.handle_info(:abcd, %{name: :normal_1})
        end)

      assert log =~ "Can't handle info :abcd"
    end
  end
end
