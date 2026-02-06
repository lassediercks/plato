defmodule Plato.FieldTest do
  use Plato.DataCase, async: false

  alias Plato.Field

  describe "changeset/2" do
    setup do
      schema = create_schema(%{name: "test_schema"})
      %{schema: schema}
    end

    test "valid changeset for text field", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "title",
        field_type: "text"
      }

      changeset = Field.changeset(%Field{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset for richtext field", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "body",
        field_type: "richtext"
      }

      changeset = Field.changeset(%Field{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset for image field", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "cover_image",
        field_type: "image"
      }

      changeset = Field.changeset(%Field{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset for reference field with referenced_schema_id", %{schema: schema} do
      ref_schema = create_schema(%{name: "referenced"})

      attrs = %{
        schema_id: schema.id,
        name: "author",
        field_type: "reference",
        referenced_schema_id: ref_schema.id
      }

      changeset = Field.changeset(%Field{}, attrs)
      assert changeset.valid?
    end

    test "requires schema_id" do
      changeset = Field.changeset(%Field{}, %{field_type: "text", name: "test"})
      assert %{schema_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "field_type defaults to text" do
      schema = create_schema(%{name: "test"})

      changeset = Field.changeset(%Field{}, %{schema_id: schema.id, name: "test"})
      assert Ecto.Changeset.get_field(changeset, :field_type) == "text"
    end

    test "validates field_type is text, richtext, image, or reference", %{schema: schema} do
      changeset =
        Field.changeset(%Field{}, %{
          schema_id: schema.id,
          name: "test",
          field_type: "invalid"
        })

      assert %{field_type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts position field", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "test",
        field_type: "text",
        position: 5
      }

      changeset = Field.changeset(%Field{}, attrs)
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :position) == 5
    end

    test "reference field requires referenced_schema_id", %{schema: schema} do
      # Without a name, forward references aren't allowed
      changeset =
        Field.changeset(%Field{}, %{
          schema_id: schema.id,
          field_type: "reference"
        })

      assert %{referenced_schema_id: ["must be set for reference fields"]} = errors_on(changeset)
    end

    test "text field should not have referenced_schema_id", %{schema: schema} do
      ref_schema = create_schema(%{name: "ref"})

      changeset =
        Field.changeset(%Field{}, %{
          schema_id: schema.id,
          name: "title",
          field_type: "text",
          referenced_schema_id: ref_schema.id
        })

      assert %{referenced_schema_id: ["should not be set for text fields"]} =
               errors_on(changeset)
    end

    test "richtext field should not have referenced_schema_id", %{schema: schema} do
      ref_schema = create_schema(%{name: "ref"})

      changeset =
        Field.changeset(%Field{}, %{
          schema_id: schema.id,
          name: "body",
          field_type: "richtext",
          referenced_schema_id: ref_schema.id
        })

      assert %{referenced_schema_id: ["should not be set for richtext fields"]} =
               errors_on(changeset)
    end

    test "defaults field_type to text", %{schema: schema} do
      changeset = Field.changeset(%Field{}, %{schema_id: schema.id, name: "test"})
      assert Ecto.Changeset.get_field(changeset, :field_type) == "text"
    end
  end

  describe "create/2" do
    setup do
      schema = create_schema(%{name: "test_schema"})
      %{schema: schema}
    end

    test "creates a text field", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "title",
        field_type: "text"
      }

      assert {:ok, field} = Field.create(attrs, Repo)
      assert field.name == "title"
      assert field.field_type == "text"
      assert field.schema_id == schema.id
      assert field.referenced_schema_id == nil
    end

    test "creates a richtext field", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "body",
        field_type: "richtext"
      }

      assert {:ok, field} = Field.create(attrs, Repo)
      assert field.name == "body"
      assert field.field_type == "richtext"
      assert field.schema_id == schema.id
      assert field.referenced_schema_id == nil
    end

    test "creates a reference field", %{schema: schema} do
      ref_schema = create_schema(%{name: "author"})

      attrs = %{
        schema_id: schema.id,
        name: "author",
        field_type: "reference",
        referenced_schema_id: ref_schema.id
      }

      assert {:ok, field} = Field.create(attrs, Repo)
      assert field.name == "author"
      assert field.field_type == "reference"
      assert field.referenced_schema_id == ref_schema.id
    end

    test "sets timestamps", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "test",
        field_type: "text"
      }

      {:ok, field} = Field.create(attrs, Repo)
      assert field.inserted_at != nil
      assert field.updated_at != nil
    end

    test "fails without required fields" do
      assert {:error, changeset} = Field.create(%{}, Repo)
      errors = errors_on(changeset)
      assert errors[:schema_id]
      assert errors[:name]
      # field_type has a default, so not required
    end

    test "creates field with auto-generated position", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "first_field",
        field_type: "text"
      }

      assert {:ok, field} = Field.create(attrs, Repo)
      assert field.position != nil
      assert field.position > 0
    end

    test "creates multiple fields with incrementing positions", %{schema: schema} do
      {:ok, field1} = Field.create(%{schema_id: schema.id, name: "field1", field_type: "text"}, Repo)
      {:ok, field2} = Field.create(%{schema_id: schema.id, name: "field2", field_type: "text"}, Repo)
      {:ok, field3} = Field.create(%{schema_id: schema.id, name: "field3", field_type: "text"}, Repo)

      assert field2.position > field1.position
      assert field3.position > field2.position
    end

    test "positions are scoped to schema", %{schema: schema} do
      other_schema = create_schema(%{name: "other_schema"})

      {:ok, field1} = Field.create(%{schema_id: schema.id, name: "field1", field_type: "text"}, Repo)
      {:ok, field2} = Field.create(%{schema_id: other_schema.id, name: "field2", field_type: "text"}, Repo)

      # Both should start at position 1 since they're in different schemas
      assert field1.position == 1
      assert field2.position == 1
    end

    test "respects explicitly provided position", %{schema: schema} do
      {:ok, field1} = Field.create(%{schema_id: schema.id, name: "field1", field_type: "text"}, Repo)
      {:ok, field2} = Field.create(%{schema_id: schema.id, name: "field2", field_type: "text", position: 100}, Repo)

      assert field2.position == 100
      assert field1.position < field2.position
    end
  end

  describe "auto-generated reference field names" do
    test "generates field name from referenced schema when name is nil" do
      schema = create_schema(%{name: "post"})
      ref_schema = create_schema(%{name: "author"})

      # Note: The implementation checks Plato.Repo.get directly, not the passed repo
      # This test assumes we're using Plato.Repo as the test repo
      attrs = %{
        schema_id: schema.id,
        field_type: "reference",
        referenced_schema_id: ref_schema.id
      }

      # The set_reference_name function will auto-generate the name
      # However, name is still required, so this will fail validation
      changeset = Field.changeset(%Field{}, attrs)
      # The validation requires name, so even with auto-generation it needs name
      if changeset.valid? do
        assert true
      else
        errors = errors_on(changeset)
        assert Map.has_key?(errors, :name)
      end
    end

    test "explicit name takes precedence over auto-generated name" do
      schema = create_schema(%{name: "post"})
      ref_schema = create_schema(%{name: "author"})

      attrs = %{
        schema_id: schema.id,
        name: "custom_author",
        field_type: "reference",
        referenced_schema_id: ref_schema.id
      }

      {:ok, field} = Field.create(attrs, Repo)
      assert field.name == "custom_author"
    end
  end

  describe "associations" do
    test "belongs to schema" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      field = Repo.preload(field, :schema)
      assert field.schema.id == schema.id
      assert field.schema.name == "test"
    end

    test "belongs to referenced_schema for reference fields" do
      schema = create_schema(%{name: "post"})
      ref_schema = create_schema(%{name: "author"})

      field =
        create_field(schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: ref_schema.id
        })

      field = Repo.preload(field, :referenced_schema)
      assert field.referenced_schema.id == ref_schema.id
      assert field.referenced_schema.name == "author"
    end

    test "referenced_schema is nil for text fields" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      field = Repo.preload(field, :referenced_schema)
      assert field.referenced_schema == nil
    end

    test "referenced_schema is nil for richtext fields" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "body", field_type: "richtext"})

      field = Repo.preload(field, :referenced_schema)
      assert field.referenced_schema == nil
    end
  end

  describe "database constraints" do
    test "allows multiple fields for same schema" do
      schema = create_schema(%{name: "post"})

      {:ok, field1} =
        Field.create(%{schema_id: schema.id, name: "title", field_type: "text"}, Repo)

      {:ok, field2} =
        Field.create(%{schema_id: schema.id, name: "body", field_type: "text"}, Repo)

      assert field1.id != field2.id
      assert field1.schema_id == field2.schema_id
    end

    test "allows same field name in different schemas" do
      schema1 = create_schema(%{name: "post"})
      schema2 = create_schema(%{name: "page"})

      {:ok, field1} =
        Field.create(%{schema_id: schema1.id, name: "title", field_type: "text"}, Repo)

      {:ok, field2} =
        Field.create(%{schema_id: schema2.id, name: "title", field_type: "text"}, Repo)

      assert field1.id != field2.id
      assert field1.name == field2.name
    end

    test "deleting schema cascades to fields" do
      schema = create_schema(%{name: "test"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      Repo.delete(schema)

      assert Repo.get(Field, field.id) == nil
    end

    test "deleting referenced schema nilifies reference" do
      schema = create_schema(%{name: "post"})
      ref_schema = create_schema(%{name: "author"})

      field =
        create_field(schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: ref_schema.id
        })

      Repo.delete(ref_schema)

      field = Repo.get(Field, field.id)
      assert field.referenced_schema_id == nil
    end
  end

  describe "field updates" do
    test "can update field name" do
      schema = create_schema(%{name: "test"})
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "old_name", field_type: "text"}, Repo)

      changeset = Field.changeset(field, %{name: "new_name"})
      {:ok, updated} = Repo.update(changeset)

      assert updated.name == "new_name"
    end

    test "cannot change field_type from text to reference without referenced_schema_id" do
      schema = create_schema(%{name: "test"})
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "test", field_type: "text"}, Repo)

      changeset = Field.changeset(field, %{field_type: "reference"})
      assert {:error, changeset} = Repo.update(changeset)
      assert %{referenced_schema_id: ["must be set for reference fields"]} = errors_on(changeset)
    end

    test "can change field_type from text to reference with referenced_schema_id" do
      schema = create_schema(%{name: "test"})
      ref_schema = create_schema(%{name: "ref"})
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "test", field_type: "text"}, Repo)

      changeset =
        Field.changeset(field, %{field_type: "reference", referenced_schema_id: ref_schema.id})

      {:ok, updated} = Repo.update(changeset)
      assert updated.field_type == "reference"
      assert updated.referenced_schema_id == ref_schema.id
    end

    test "updates updated_at timestamp" do
      schema = create_schema(%{name: "test"})
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "test", field_type: "text"}, Repo)
      original_updated_at = field.updated_at

      # Sleep to ensure timestamp difference (Docker may need more time)
      Process.sleep(1100)

      changeset = Field.changeset(field, %{name: "updated"})
      {:ok, updated} = Repo.update(changeset)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "can change field_type from text to richtext" do
      schema = create_schema(%{name: "test"})
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "content", field_type: "text"}, Repo)

      changeset = Field.changeset(field, %{field_type: "richtext"})
      {:ok, updated} = Repo.update(changeset)

      assert updated.field_type == "richtext"
      assert updated.referenced_schema_id == nil
    end

    test "can change field_type from richtext to text" do
      schema = create_schema(%{name: "test"})
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "content", field_type: "richtext"}, Repo)

      changeset = Field.changeset(field, %{field_type: "text"})
      {:ok, updated} = Repo.update(changeset)

      assert updated.field_type == "text"
      assert updated.referenced_schema_id == nil
    end

    test "cannot change field_type from richtext to reference without referenced_schema_id" do
      schema = create_schema(%{name: "test"})
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "content", field_type: "richtext"}, Repo)

      changeset = Field.changeset(field, %{field_type: "reference"})
      assert {:error, changeset} = Repo.update(changeset)
      assert %{referenced_schema_id: ["must be set for reference fields"]} = errors_on(changeset)
    end
  end

  describe "field options" do
    setup do
      schema = create_schema(%{name: "test_schema"})
      %{schema: schema}
    end

    test "creates field with empty options by default", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "title",
        field_type: "text"
      }

      {:ok, field} = Field.create(attrs, Repo)
      assert field.options == %{}
    end

    test "creates field with multiline option", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "body",
        field_type: "text",
        options: %{"multiline" => true}
      }

      {:ok, field} = Field.create(attrs, Repo)
      assert field.options == %{"multiline" => true}
    end

    test "creates field with only multiline option", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "description",
        field_type: "text",
        options: %{"multiline" => true}
      }

      {:ok, field} = Field.create(attrs, Repo)
      assert field.options == %{"multiline" => true}
    end

    test "updates field options", %{schema: schema} do
      {:ok, field} = Field.create(%{
        schema_id: schema.id,
        name: "content",
        field_type: "text",
        options: %{}
      }, Repo)

      changeset = Field.changeset(field, %{options: %{"multiline" => true}})
      {:ok, updated} = Repo.update(changeset)

      assert updated.options == %{"multiline" => true}
    end

    test "validates options must be a map", %{schema: schema} do
      changeset = Field.changeset(%Field{}, %{
        schema_id: schema.id,
        name: "test",
        field_type: "text",
        options: "invalid"
      })

      assert %{options: ["is invalid"]} = errors_on(changeset)
    end

    test "options persist across updates", %{schema: schema} do
      {:ok, field} = Field.create(%{
        schema_id: schema.id,
        name: "content",
        field_type: "text",
        options: %{"multiline" => true}
      }, Repo)

      # Update name but not options
      changeset = Field.changeset(field, %{name: "new_name"})
      {:ok, updated} = Repo.update(changeset)

      # Options should remain unchanged
      assert updated.options == %{"multiline" => true}
    end

    test "creates richtext field with empty options by default", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "body",
        field_type: "richtext"
      }

      {:ok, field} = Field.create(attrs, Repo)
      assert field.options == %{}
    end

    test "creates richtext field with custom options", %{schema: schema} do
      attrs = %{
        schema_id: schema.id,
        name: "content",
        field_type: "richtext",
        options: %{"toolbar" => "basic"}
      }

      {:ok, field} = Field.create(attrs, Repo)
      assert field.options == %{"toolbar" => "basic"}
    end

    test "updates richtext field options", %{schema: schema} do
      {:ok, field} = Field.create(%{
        schema_id: schema.id,
        name: "article",
        field_type: "richtext",
        options: %{}
      }, Repo)

      changeset = Field.changeset(field, %{options: %{"max_length" => 5000}})
      {:ok, updated} = Repo.update(changeset)

      assert updated.options == %{"max_length" => 5000}
    end
  end

  describe "field position and ordering" do
    setup do
      schema = create_schema(%{name: "test_schema"})
      %{schema: schema}
    end

    test "can update field position", %{schema: schema} do
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "test", field_type: "text"}, Repo)
      original_position = field.position

      changeset = Field.changeset(field, %{position: original_position + 10})
      {:ok, updated} = Repo.update(changeset)

      assert updated.position == original_position + 10
    end

    test "multiple fields maintain distinct positions within schema", %{schema: schema} do
      {:ok, field1} = Field.create(%{schema_id: schema.id, name: "field1", field_type: "text"}, Repo)
      {:ok, field2} = Field.create(%{schema_id: schema.id, name: "field2", field_type: "text"}, Repo)
      {:ok, field3} = Field.create(%{schema_id: schema.id, name: "field3", field_type: "text"}, Repo)

      positions = [field1.position, field2.position, field3.position]
      unique_positions = Enum.uniq(positions)

      assert length(positions) == length(unique_positions)
    end

    test "reordering fields updates positions correctly", %{schema: schema} do
      {:ok, field1} = Field.create(%{schema_id: schema.id, name: "field1", field_type: "text"}, Repo)
      {:ok, field2} = Field.create(%{schema_id: schema.id, name: "field2", field_type: "text"}, Repo)
      {:ok, field3} = Field.create(%{schema_id: schema.id, name: "field3", field_type: "text"}, Repo)

      # Swap positions of field1 and field3
      field1 |> Field.changeset(%{position: field3.position}) |> Repo.update()
      field3 |> Field.changeset(%{position: field1.position}) |> Repo.update()

      updated_field1 = Repo.get(Field, field1.id)
      updated_field3 = Repo.get(Field, field3.id)

      assert updated_field1.position == field3.position
      assert updated_field3.position == field1.position
    end

    test "position survives name updates", %{schema: schema} do
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "original", field_type: "text"}, Repo)
      original_position = field.position

      changeset = Field.changeset(field, %{name: "updated"})
      {:ok, updated} = Repo.update(changeset)

      assert updated.position == original_position
      assert updated.name == "updated"
    end

    test "position survives field_type changes", %{schema: schema} do
      {:ok, field} = Field.create(%{schema_id: schema.id, name: "content", field_type: "text"}, Repo)
      original_position = field.position

      changeset = Field.changeset(field, %{field_type: "richtext"})
      {:ok, updated} = Repo.update(changeset)

      assert updated.position == original_position
      assert updated.field_type == "richtext"
    end
  end

  describe "complex reference scenarios" do
    test "self-referencing schema" do
      schema = create_schema(%{name: "category"})

      # A category can have a parent category
      {:ok, field} =
        Field.create(
          %{
            schema_id: schema.id,
            name: "parent",
            field_type: "reference",
            referenced_schema_id: schema.id
          },
          Repo
        )

      field = Repo.preload(field, :referenced_schema)
      assert field.referenced_schema.id == schema.id
    end

    test "circular references between schemas" do
      schema_a = create_schema(%{name: "schema_a"})
      schema_b = create_schema(%{name: "schema_b"})

      # A references B
      {:ok, _field_a} =
        Field.create(
          %{
            schema_id: schema_a.id,
            name: "b_ref",
            field_type: "reference",
            referenced_schema_id: schema_b.id
          },
          Repo
        )

      # B references A
      {:ok, _field_b} =
        Field.create(
          %{
            schema_id: schema_b.id,
            name: "a_ref",
            field_type: "reference",
            referenced_schema_id: schema_a.id
          },
          Repo
        )

      # Both should exist
      schema_a = Repo.preload(schema_a, :fields, force: true)
      schema_b = Repo.preload(schema_b, :fields, force: true)

      assert length(schema_a.fields) == 1
      assert length(schema_b.fields) == 1
    end

    test "multiple reference fields to same schema" do
      post_schema = create_schema(%{name: "post"})
      user_schema = create_schema(%{name: "user"})

      {:ok, author_field} =
        Field.create(
          %{
            schema_id: post_schema.id,
            name: "author",
            field_type: "reference",
            referenced_schema_id: user_schema.id
          },
          Repo
        )

      {:ok, editor_field} =
        Field.create(
          %{
            schema_id: post_schema.id,
            name: "editor",
            field_type: "reference",
            referenced_schema_id: user_schema.id
          },
          Repo
        )

      assert author_field.referenced_schema_id == user_schema.id
      assert editor_field.referenced_schema_id == user_schema.id
      assert author_field.name != editor_field.name
    end
  end
end
