defmodule Plato.Repo.Migrations.CreatePlatoTables do
  use Ecto.Migration

  def change do
    # Create schemas table
    create table(:schemas) do
      add :name, :string, null: false
      add :unique, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:schemas, [:name])

    # Create fields table
    create table(:fields) do
      add :name, :string, null: false
      add :field_type, :string, null: false, default: "text"
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false
      add :referenced_schema_id, references(:schemas, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:fields, [:schema_id])
    create index(:fields, [:referenced_schema_id])

    # Create contents table
    create table(:contents) do
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false
      add :field_values, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:contents, [:schema_id])
  end
end
