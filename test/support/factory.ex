defmodule AsyncTaskDemo.Factory do
  use ExMachina.Ecto, repo: AsyncTaskDemo.Repo

  alias AsyncTaskDemo.Tasks.Task

  def task_factory do
    %Task{
      type: "report",
      priority: :normal,
      data: %{},
      state: :new,
      attempt: 0,
      max_attempts: 5
    }
  end
end
