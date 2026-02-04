defmodule Plato.Repo.Migrations.AddFieldTypeAndReference do
  use Ecto.Migration

  def change do
    alter table(:fields) do
      add :field_type, :string, null: false, default: "text"
      add :referenced_schema_id, references(:schemas, on_delete: :nilify_all)
    end

    create index(:fields, [:referenced_schema_id])
  end
end
