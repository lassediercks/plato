defmodule Plato.TestRepo do
  @moduledoc false
  def insert(%Ecto.Changeset{} = changeset) do
    {:ok, Ecto.Changeset.apply_changes(changeset)}
  end

  def insert(struct), do: {:ok, struct}
end

defmodule Plato.SchemaTest do
  use ExUnit.Case, async: true

  test "creates a new schema via Plato.Schema.create/2" do
    attrs = %{name: "Test Schema"}

    assert {:ok, %Plato.Schema{} = schema} = Plato.Schema.create(attrs, Plato.TestRepo)
    assert schema.name == "Test Schema"
    assert schema.id == nil
  end
end
