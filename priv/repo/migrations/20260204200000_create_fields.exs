defmodule Plato.Repo.Migrations.CreateFields do
  use Ecto.Migration

  def change do
    create table(:fields) do
      add :name, :string, null: false
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:fields, [:schema_id])
  end
end
