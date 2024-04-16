defmodule AsyncTaskDemo.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :type, :string, null: false
      add :priority, :integer, null: false, default: 3
      add :data, :map

      add :state, :string, null: false, default: "new"
      add :attempt, :integer, null: false, default: 0
      add :max_attempts, :integer, null: false, default: 5

      timestamps()
    end

    create index(:tasks, [:id], where: "state = 'new'")
  end
end
