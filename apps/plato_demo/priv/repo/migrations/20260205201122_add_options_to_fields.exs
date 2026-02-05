defmodule Plato.Repo.Migrations.AddOptionsToFields do
  use Ecto.Migration

  def change do
    alter table(:fields) do
      add :options, :map, default: %{}, null: false
    end

    # Add index on options for performance when querying by options
    create index(:fields, [:options], using: :gin)
  end
end
