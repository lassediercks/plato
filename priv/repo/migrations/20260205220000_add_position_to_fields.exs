defmodule Plato.Repo.Migrations.AddPositionToFields do
  use Ecto.Migration

  def change do
    alter table(:fields) do
      add :position, :integer
    end

    # Set initial positions based on ID order within each schema
    execute(
      """
      UPDATE fields f1
      SET position = (
        SELECT COUNT(*)
        FROM fields f2
        WHERE f2.schema_id = f1.schema_id
        AND f2.id <= f1.id
      )
      WHERE position IS NULL
      """,
      "UPDATE fields SET position = NULL"
    )

    # Make position not null after setting initial values
    alter table(:fields) do
      modify :position, :integer, null: false
    end

    # Add index on schema_id and position for efficient ordering
    create index(:fields, [:schema_id, :position])
  end
end
