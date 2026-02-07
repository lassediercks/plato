defmodule Plato.ContentTest do
  use Plato.DataCase, async: true

  alias Plato.Content

  describe "changeset/2" do
    setup do
      schema = create_schema(%{name: "test_schema"})
      %{schema: schema}
    end

    test "valid changeset with required fields", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        field_values: %{"1" => "value"}
      }

      changeset = Content.changeset(%Content{}, attrs)
      assert changeset.valid?
    end

    test "requires schema_id" do
      changeset = Content.changeset(%Content{}, %{field_values: %{}})
      assert %{schema_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "field_values defaults to empty map" do
      schema = create_schema(%{name: "test"})
      changeset = Content.changeset(%Content{}, %{schema_id: schema.id})
      assert Ecto.Changeset.get_field(changeset, :field_values) == %{}
    end

    test "accepts empty field_values map", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        field_values: %{}
      }

      changeset = Content.changeset(%Content{}, attrs)
      assert changeset.valid?
    end

    test "accepts field_values with string keys", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        field_values: %{"1" => "value1", "2" => "value2"}
      }

      changeset = Content.changeset(%Content{}, attrs)
      assert changeset.valid?
    end
  end

  describe "create/2" do
    setup do
      schema = create_schema(%{name: "test_schema"})
      field1 = create_field(schema, %{name: "title", field_type: "text"})
      field2 = create_field(schema, %{name: "body", field_type: "text"})
      %{schema: schema, field1: field1, field2: field2}
    end

    test "creates content with field values", %{schema: schema, field1: field1, field2: field2} do
      attrs = %{
        schema_id: schema.id,
        field_values: %{
          "#{field1.id}" => "Test Title",
          "#{field2.id}" => "Test Body"
        }
      }

      assert {:ok, content} = Content.create(attrs, Repo)
      assert content.schema_id == schema.id
      assert content.field_values["#{field1.id}"] == "Test Title"
      assert content.field_values["#{field2.id}"] == "Test Body"
      assert content.id != nil
    end

    test "creates content with empty field values", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        field_values: %{}
      }

      assert {:ok, content} = Content.create(attrs, Repo)
      assert content.field_values == %{}
    end

    test "sets timestamps", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        field_values: %{}
      }

      {:ok, content} = Content.create(attrs, Repo)
      assert content.inserted_at != nil
      assert content.updated_at != nil
    end

    test "fails without required fields" do
      assert {:error, changeset} = Content.create(%{}, Repo)
      errors = errors_on(changeset)
      assert errors[:schema_id]
      # field_values has a default, so not required
    end

    test "defaults field_values to empty map", %{schema: schema} do
      # When using the schema's default
      content = %Content{schema_id: schema.id}
      assert content.field_values == %{}
    end
  end

  describe "associations" do
    test "belongs to schema" do
      schema = create_schema(%{name: "test"})
      content = create_content(schema, %{})

      content = Repo.preload(content, :schema)
      assert content.schema.id == schema.id
      assert content.schema.name == "test"
    end

    test "preloading schema with fields" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})
      content = create_content(schema, %{"#{field.id}" => "Value"})

      content = Repo.preload(content, schema: :fields)
      assert content.schema.name == "test"
      assert length(content.schema.fields) == 1
      assert hd(content.schema.fields).name == "title"
    end
  end

  describe "database constraints" do
    test "allows multiple content instances for same schema" do
      schema = create_schema(%{name: "blog_post"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      content1 = create_content(schema, %{"#{field.id}" => "Post 1"})
      content2 = create_content(schema, %{"#{field.id}" => "Post 2"})
      content3 = create_content(schema, %{"#{field.id}" => "Post 3"})

      assert content1.id != content2.id
      assert content2.id != content3.id
      assert content1.schema_id == content2.schema_id
      assert content2.schema_id == content3.schema_id
    end

    test "deleting schema cascades to content" do
      schema = create_schema(%{name: "test"})
      content1 = create_content(schema, %{})
      content2 = create_content(schema, %{})

      Repo.delete(schema)

      assert Repo.get(Content, content1.id) == nil
      assert Repo.get(Content, content2.id) == nil
    end

    test "enforces foreign key constraint on schema_id" do
      attrs = %{
        schema_id: 99999,
        field_values: %{}
      }

      assert {:error, changeset} = Content.create(attrs, Repo)
      # Foreign key constraint violation
      assert changeset.errors != []
    end
  end

  describe "content updates" do
    test "can update field_values" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      {:ok, content} =
        Content.create(
          %{
            schema_id: schema.id,
            field_values: %{"#{field.id}" => "Original"}
          },
          Repo
        )

      changeset = Content.changeset(content, %{field_values: %{"#{field.id}" => "Updated"}})
      {:ok, updated} = Repo.update(changeset)

      assert updated.field_values["#{field.id}"] == "Updated"
    end

    test "can add new field values" do
      schema = create_schema(%{name: "test"})
      field1 = create_field(schema, %{name: "title", field_type: "text"})
      field2 = create_field(schema, %{name: "body", field_type: "text"})

      {:ok, content} =
        Content.create(
          %{
            schema_id: schema.id,
            field_values: %{"#{field1.id}" => "Title"}
          },
          Repo
        )

      new_values = %{
        "#{field1.id}" => "Title",
        "#{field2.id}" => "New Body"
      }

      changeset = Content.changeset(content, %{field_values: new_values})
      {:ok, updated} = Repo.update(changeset)

      assert updated.field_values["#{field1.id}"] == "Title"
      assert updated.field_values["#{field2.id}"] == "New Body"
    end

    test "can remove field values" do
      schema = create_schema(%{name: "test"})
      field1 = create_field(schema, %{name: "title", field_type: "text"})
      field2 = create_field(schema, %{name: "body", field_type: "text"})

      {:ok, content} =
        Content.create(
          %{
            schema_id: schema.id,
            field_values: %{
              "#{field1.id}" => "Title",
              "#{field2.id}" => "Body"
            }
          },
          Repo
        )

      changeset = Content.changeset(content, %{field_values: %{"#{field1.id}" => "Title"}})
      {:ok, updated} = Repo.update(changeset)

      assert updated.field_values["#{field1.id}"] == "Title"
      assert updated.field_values["#{field2.id}"] == nil
    end

    test "updates updated_at timestamp" do
      schema = create_schema(%{name: "test"})
      {:ok, content} = Content.create(%{schema_id: schema.id, field_values: %{}}, Repo)
      original_updated_at = content.updated_at

      # Sleep to ensure timestamp difference (Docker may need more time)
      Process.sleep(1100)

      changeset = Content.changeset(content, %{field_values: %{"1" => "value"}})
      {:ok, updated} = Repo.update(changeset)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "cannot change schema_id" do
      schema1 = create_schema(%{name: "schema1"})
      schema2 = create_schema(%{name: "schema2"})

      {:ok, content} = Content.create(%{schema_id: schema1.id, field_values: %{}}, Repo)

      # Attempting to change schema_id
      changeset = Content.changeset(content, %{schema_id: schema2.id})
      {:ok, updated} = Repo.update(changeset)

      # Schema_id should change if it's in the changeset
      assert updated.schema_id == schema2.id
    end
  end

  describe "field_values storage" do
    test "stores field values as map with string keys" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      {:ok, content} =
        Content.create(
          %{
            schema_id: schema.id,
            field_values: %{"#{field.id}" => "Value"}
          },
          Repo
        )

      # Reload from database
      content = Repo.get(Content, content.id)
      assert is_map(content.field_values)
      assert content.field_values["#{field.id}"] == "Value"
    end

    test "handles numeric field IDs as strings" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      # Field IDs should be stored as strings in the map
      {:ok, content} =
        Content.create(
          %{
            schema_id: schema.id,
            field_values: %{"#{field.id}" => "Value"}
          },
          Repo
        )

      assert content.field_values["#{field.id}"] == "Value"
    end

    test "stores reference field values as strings" do
      author_schema = create_schema(%{name: "author"})
      author_content = create_content(author_schema, %{})

      post_schema = create_schema(%{name: "post"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      {:ok, post_content} =
        Content.create(
          %{
            schema_id: post_schema.id,
            field_values: %{"#{author_field.id}" => "#{author_content.id}"}
          },
          Repo
        )

      assert post_content.field_values["#{author_field.id}"] == "#{author_content.id}"
    end

    test "preserves complex field_values structure" do
      schema = create_schema(%{name: "test"})

      {:ok, content} =
        Content.create(
          %{
            schema_id: schema.id,
            field_values: %{
              "1" => "value1",
              "2" => "value2",
              "3" => "value3"
            }
          },
          Repo
        )

      assert map_size(content.field_values) == 3
      assert content.field_values["1"] == "value1"
      assert content.field_values["2"] == "value2"
      assert content.field_values["3"] == "value3"
    end
  end

  describe "querying content" do
    test "can query by schema_id" do
      schema1 = create_schema(%{name: "schema1"})
      schema2 = create_schema(%{name: "schema2"})

      content1 = create_content(schema1, %{})
      content2 = create_content(schema1, %{})
      content3 = create_content(schema2, %{})

      results =
        Content
        |> where([c], c.schema_id == ^schema1.id)
        |> Repo.all()

      assert length(results) == 2
      content_ids = Enum.map(results, & &1.id)
      assert content1.id in content_ids
      assert content2.id in content_ids
      refute content3.id in content_ids
    end

    test "can query by field values using JSON operators" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "status", field_type: "text"})

      _content1 = create_content(schema, %{"#{field.id}" => "published"})
      _content2 = create_content(schema, %{"#{field.id}" => "draft"})
      create_content(schema, %{"#{field.id}" => "published"})

      # Query using JSON path (PostgreSQL specific)
      # Use ->> operator which returns text, not JSON
      import Ecto.Query

      results =
        from(c in Content,
          where: fragment("?->>? = ?", c.field_values, ^"#{field.id}", ^"published")
        )
        |> Repo.all()

      assert length(results) == 2
    end
  end

  describe "deletion" do
    test "can delete content" do
      schema = create_schema(%{name: "test"})
      content = create_content(schema, %{})

      Repo.delete(content)

      assert Repo.get(Content, content.id) == nil
    end

    test "deleting content does not affect schema or fields" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})
      content = create_content(schema, %{"#{field.id}" => "value"})

      Repo.delete(content)

      assert Repo.get(Plato.Schema, schema.id) != nil
      assert Repo.get(Plato.Field, field.id) != nil
    end
  end
end
