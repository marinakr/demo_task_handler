defmodule AsyncTaskDemo.Tasks.PerformerTest do
  use AsyncTaskDemo.DataCase, async: true
  import Mimic

  alias AsyncTaskDemo.Tasks.Performer
  alias AsyncTaskDemo.Tasks.Task

  describe "run/1" do
    test "works successfully for 'check'" do
      assert :ok = Performer.run(%Task{type: "check"})
    end

    test "works successfully for 'report'" do
      assert {:ok, _} = Performer.run(%Task{type: "report"})
    end

    test "can returns both ok and error for http call" do
      task = %Task{
        type: "email",
        data: %{to: "receiver@mail.com", message: "Hello", topic: "task testing"}
      }

      expect(HTTPoison, :post, fn _, _ ->
        {:error, %HTTPoison.Error{}}
      end)

      assert {:error, _} = Performer.run(task)

      expect(HTTPoison, :post, fn _, _ ->
        {:ok, %HTTPoison.Response{status_code: 200, body: "OK", headers: []}}
      end)

      assert {:ok, _} = Performer.run(task)
    end

    test "raises error" do
      result =
        try do
          Performer.run(%Task{type: "email"})
        catch
          what, why ->
            {what, why}
        end

      assert {:error, %RuntimeError{message: "Invalid email data"}} = result
    end

    test "returns error" do
      log =
        capture_log(fn ->
          assert {:error, :unknown_task} = Performer.run(%Task{type: "calculate something"})
        end)

      assert log =~ "No pattern for task"
    end
  end
end
