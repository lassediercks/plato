defmodule Plato.Repo.Migrations.AddManagedByToSchemas do
  use Ecto.Migration

  def change do
    alter table(:schemas) do
      add :managed_by, :string, default: "ui", null: false
    end

    create index(:schemas, [:managed_by])
  end
end
