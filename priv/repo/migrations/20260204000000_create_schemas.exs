defmodule Plato.Repo.Migrations.CreateSchemas do
  use Ecto.Migration

  def change do
    create table(:schemas) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:schemas, [:name])
  end
end
