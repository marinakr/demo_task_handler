defmodule AsyncTaskDemo.Tasks.Performer do
  @moduledoc """
  Modules describe logic to perform task depends on task type and data 
  """

  alias AsyncTaskDemo.Tasks.Task

  require Logger

  @from "user.name@taks.com"

  @doc """
  Specification to execute task
  Results `:ok`, `{:ok, _}` counts task was completed successfully
  Otherwise, application will try to execute task again, until max_attempts is reached

  ## Parametes
        - task: Task.t()

  ## Examples

    iex> AsyncTaskDemo.Tasks.Performer.run(%AsyncTaskDemo.Tasks.Task{type: "report"})
    {:ok, "report generated"}

    iex> AsyncTaskDemo.Tasks.Performer.run(%AsyncTaskDemo.Tasks.Task{type: "some actions"})
    {:error, :unknown_task}
  """

  @spec run(Task.t()) :: :ok | {:ok, term()} | term()
  def run(%Task{type: "check"}) do
    # example of job successfully completed with 1 attempt with :ok return

    :ok
  end

  def run(%Task{type: "report", data: _data}) do
    # example of job successfully completed with 1 attempt with {:ok, _} return

    # some logic to generated report
    {:ok, "report generated"}
  end

  def run(%Task{type: "email", data: %{to: to, message: message, topic: topic}})
      when is_binary(to) and is_binary(message) and is_binary(topic) do
    # example of job successfully completed with few attempts
    # in test, mock http call with few failed attempts before final successfull call

    # some logic to send email
    body = Jason.encode!(%{message: message, topic: topic, to: to, from: @from})
    HTTPoison.post("localhost/emails", body)
  end

  def run(%Task{type: "email", data: _data}) do
    # example of job always raises error
    raise "Invalid email data"
  end

  def run(%Task{id: id, type: type, priority: priority}) do
    # example of job that never succeeds

    Logger.error("No pattern for task", task_id: id, task_type: type, task_priority: priority)
    {:error, :unknown_task}
  end
end
