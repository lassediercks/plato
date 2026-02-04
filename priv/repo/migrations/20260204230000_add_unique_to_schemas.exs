defmodule Plato.Repo.Migrations.AddUniqueToSchemas do
  use Ecto.Migration

  def change do
    alter table(:schemas) do
      add :unique, :boolean, default: false, null: false
    end
  end
end
