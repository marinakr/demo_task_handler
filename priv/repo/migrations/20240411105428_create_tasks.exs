defmodule AsyncTaskDemo.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :type, :string, null: false
      add :priority, :integer, null: false
      add :data, :map

      timestamps()
    end

    create index(:tasks, [:type, :priority])
  end
end
