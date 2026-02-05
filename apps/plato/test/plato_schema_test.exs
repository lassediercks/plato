defmodule Plato.SchemaTest do
  use Plato.DataCase, async: true

  alias Plato.Schema

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset = Schema.changeset(%Schema{}, %{name: "test_schema"})
      assert changeset.valid?
    end

    test "requires name field" do
      changeset = Schema.changeset(%Schema{}, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "defaults unique to false" do
      changeset = Schema.changeset(%Schema{}, %{name: "test"})
      assert Ecto.Changeset.get_field(changeset, :unique) == false
    end

    test "accepts unique as true" do
      changeset = Schema.changeset(%Schema{}, %{name: "test", unique: true})
      assert Ecto.Changeset.get_field(changeset, :unique) == true
    end

    test "defaults managed_by to ui" do
      changeset = Schema.changeset(%Schema{}, %{name: "test"})
      assert Ecto.Changeset.get_field(changeset, :managed_by) == "ui"
    end

    test "accepts managed_by as code" do
      changeset = Schema.changeset(%Schema{}, %{name: "test", managed_by: "code"})
      assert Ecto.Changeset.get_field(changeset, :unique) == false
      assert Ecto.Changeset.get_field(changeset, :managed_by) == "code"
    end

    test "validates managed_by is either ui or code" do
      changeset = Schema.changeset(%Schema{}, %{name: "test", managed_by: "invalid"})
      assert %{managed_by: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid fields" do
      attrs = %{
        name: "blog_post",
        unique: false,
        managed_by: "code"
      }

      changeset = Schema.changeset(%Schema{}, attrs)
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :name) == "blog_post"
      assert Ecto.Changeset.get_field(changeset, :unique) == false
      assert Ecto.Changeset.get_field(changeset, :managed_by) == "code"
    end
  end

  describe "create/2" do
    test "creates a schema with valid attributes" do
      attrs = %{name: "article", unique: false}
      assert {:ok, schema} = Schema.create(attrs, Repo)
      assert schema.name == "article"
      assert schema.unique == false
      assert schema.id != nil
    end

    test "creates a unique schema" do
      attrs = %{name: "homepage", unique: true}
      assert {:ok, schema} = Schema.create(attrs, Repo)
      assert schema.unique == true
    end

    test "creates a code-managed schema" do
      attrs = %{name: "settings", managed_by: "code"}
      assert {:ok, schema} = Schema.create(attrs, Repo)
      assert schema.managed_by == "code"
    end

    test "fails without required name" do
      assert {:error, changeset} = Schema.create(%{}, Repo)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "sets timestamps" do
      {:ok, schema} = Schema.create(%{name: "test"}, Repo)
      assert schema.inserted_at != nil
      assert schema.updated_at != nil
    end
  end

  describe "database constraints" do
    test "enforces unique schema names" do
      {:ok, _schema1} = Schema.create(%{name: "duplicate"}, Repo)

      assert {:error, changeset} = Schema.create(%{name: "duplicate"}, Repo)
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows multiple schemas with different names" do
      {:ok, schema1} = Schema.create(%{name: "schema1"}, Repo)
      {:ok, schema2} = Schema.create(%{name: "schema2"}, Repo)
      {:ok, schema3} = Schema.create(%{name: "schema3"}, Repo)

      assert schema1.id != schema2.id
      assert schema2.id != schema3.id
    end
  end

  describe "associations" do
    test "has_many fields relationship" do
      schema = create_schema(%{name: "test"})
      create_field(schema, %{name: "field1", field_type: "text"})
      create_field(schema, %{name: "field2", field_type: "text"})

      schema = Repo.preload(schema, :fields)
      assert length(schema.fields) == 2
    end

    test "deleting schema cascades to fields" do
      schema = create_schema(%{name: "test"})
      field1 = create_field(schema, %{name: "field1", field_type: "text"})
      field2 = create_field(schema, %{name: "field2", field_type: "text"})

      Repo.delete(schema)

      assert Repo.get(Plato.Field, field1.id) == nil
      assert Repo.get(Plato.Field, field2.id) == nil
    end
  end

  describe "schema updates" do
    test "can update schema name" do
      {:ok, schema} = Schema.create(%{name: "original"}, Repo)

      changeset = Schema.changeset(schema, %{name: "updated"})
      {:ok, updated} = Repo.update(changeset)

      assert updated.name == "updated"
      assert updated.id == schema.id
    end

    test "can toggle unique flag" do
      {:ok, schema} = Schema.create(%{name: "test", unique: false}, Repo)

      changeset = Schema.changeset(schema, %{unique: true})
      {:ok, updated} = Repo.update(changeset)

      assert updated.unique == true
    end

    test "can change managed_by" do
      {:ok, schema} = Schema.create(%{name: "test", managed_by: "ui"}, Repo)

      changeset = Schema.changeset(schema, %{managed_by: "code"})
      {:ok, updated} = Repo.update(changeset)

      assert updated.managed_by == "code"
    end

    test "updates updated_at timestamp" do
      {:ok, schema} = Schema.create(%{name: "test"}, Repo)
      original_updated_at = schema.updated_at

      # Sleep to ensure timestamp difference (Docker may need more time)
      Process.sleep(1100)

      changeset = Schema.changeset(schema, %{name: "updated"})
      {:ok, updated} = Repo.update(changeset)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end
  end
end
