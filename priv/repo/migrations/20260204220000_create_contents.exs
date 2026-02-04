defmodule Plato.Repo.Migrations.CreateContents do
  use Ecto.Migration

  def change do
    create table(:contents) do
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false
      add :field_values, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:contents, [:schema_id])
  end
end
