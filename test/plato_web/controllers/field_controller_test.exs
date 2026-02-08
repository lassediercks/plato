defmodule PlatoWeb.FieldControllerTest do
  use PlatoWeb.ConnCase, async: true

  alias Plato.{Field, Content}

  setup %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:plato_otp_app, :plato)
      |> Plug.Conn.assign(:plato_base_path, "/admin")

    {:ok, conn: conn}
  end

  describe "create/2" do
    test "creates a text field successfully", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "title",
          "field_type" => "text"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "title"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "added successfully"

      # Verify field was created
      field = Repo.get_by(Field, schema_id: schema.id, name: "title")
      assert field != nil
      assert field.field_type == "text"
    end

    test "creates a reference field successfully", %{conn: conn} do
      ref_schema = create_schema(%{name: "authors"})
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "author",
          "field_type" => "reference",
          "referenced_schema_id" => to_string(ref_schema.id)
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "author"

      field = Repo.get_by(Field, schema_id: schema.id, name: "author")
      assert field.field_type == "reference"
      assert field.referenced_schema_id == ref_schema.id
    end

    test "creates an image field successfully", %{conn: conn} do
      schema = create_schema(%{name: "gallery"})

      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "photo",
          "field_type" => "image"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"

      field = Repo.get_by(Field, schema_id: schema.id, name: "photo")
      assert field.field_type == "image"
    end

    test "creates text field with multiline option", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "body",
          "field_type" => "text",
          "multiline" => "true"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"

      field = Repo.get_by(Field, schema_id: schema.id, name: "body")
      assert field.options["multiline"] == true
    end

    test "creates field with as_title option", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "title",
          "field_type" => "text",
          "as_title" => "on"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"

      field = Repo.get_by(Field, schema_id: schema.id, name: "title")
      assert field.options["as_title"] == true
    end

    test "normalizes empty referenced_schema_id for reference fields", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "author",
          "field_type" => "reference",
          "referenced_schema_id" => ""
        }
      }

      # This should fail validation, but tests that normalization happens
      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
    end

    test "normalizes referenced_schema_id to nil for text fields", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "title",
          "field_type" => "text",
          "referenced_schema_id" => "123"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"

      field = Repo.get_by(Field, schema_id: schema.id, name: "title")
      assert field.referenced_schema_id == nil
    end

    test "handles field creation errors", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      # Try to create with invalid field_type
      params = %{
        "schema_id" => schema.id,
        "field" => %{
          "name" => "bad_field",
          "field_type" => "invalid_type"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) != nil
    end
  end

  describe "reorder/2" do
    test "updates field positions successfully", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field1 = create_field(schema, %{name: "title", position: 0})
      field2 = create_field(schema, %{name: "body", position: 1})
      field3 = create_field(schema, %{name: "author", position: 2})

      # Reorder: field3, field1, field2
      params = %{
        "schema_id" => schema.id,
        "field_ids" => [field3.id, field1.id, field2.id]
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/reorder", params)

      assert json_response(conn, 200) == %{"success" => true}

      # Verify positions were updated
      assert Repo.get(Field, field3.id).position == 1
      assert Repo.get(Field, field1.id).position == 2
      assert Repo.get(Field, field2.id).position == 3
    end

    test "handles non-existent field IDs gracefully", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field1 = create_field(schema, %{name: "title", position: 0})

      params = %{
        "schema_id" => schema.id,
        "field_ids" => [99999, field1.id]
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/reorder", params)

      assert json_response(conn, 200) == %{"success" => true}

      # Verify field1 position was still updated
      assert Repo.get(Field, field1.id).position == 2
    end

    test "handles empty field_ids array", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "field_ids" => []
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/reorder", params)

      assert json_response(conn, 200) == %{"success" => true}
    end
  end

  describe "edit/2" do
    test "renders edit form for valid field", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      conn = get(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/edit")

      assert html_response(conn, 200)
      assert conn.assigns.schema.id == schema.id
      assert conn.assigns.field.id == field.id
      assert conn.assigns.all_schemas != nil
    end

    test "redirects when schema not found", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      conn = get(conn, "/admin/schemas/99999/fields/#{field.id}/edit")

      assert redirected_to(conn) == "/admin/schemas/99999"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when field not found", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      conn = get(conn, "/admin/schemas/#{schema.id}/fields/99999/edit")

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when field does not belong to schema", %{conn: conn} do
      schema1 = create_schema(%{name: "posts"})
      schema2 = create_schema(%{name: "pages"})
      field = create_field(schema2, %{name: "title", field_type: "text"})

      conn = get(conn, "/admin/schemas/#{schema1.id}/fields/#{field.id}/edit")

      assert redirected_to(conn) == "/admin/schemas/#{schema1.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when schema is code-managed", %{conn: conn} do
      schema = create_schema(%{name: "posts", managed_by: "code"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      conn = get(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/edit")

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "code-managed"
    end
  end

  describe "update/2" do
    test "updates field successfully", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      params = %{
        "schema_id" => schema.id,
        "id" => field.id,
        "field" => %{
          "name" => "updated_title"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/update", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "updated successfully"

      updated_field = Repo.get(Field, field.id)
      assert updated_field.name == "updated_title"
    end

    test "updates text field options", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "body", field_type: "text"})

      params = %{
        "schema_id" => schema.id,
        "id" => field.id,
        "field" => %{
          "name" => "body",
          "multiline" => "true",
          "as_title" => "on"
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/update", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"

      updated_field = Repo.get(Field, field.id)
      assert updated_field.options["multiline"] == true
      assert updated_field.options["as_title"] == true
    end

    test "redirects when field not found", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      params = %{
        "schema_id" => schema.id,
        "id" => 99999,
        "field" => %{"name" => "test"}
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/99999/update", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when field does not belong to schema", %{conn: conn} do
      schema1 = create_schema(%{name: "posts"})
      schema2 = create_schema(%{name: "pages"})
      field = create_field(schema2, %{name: "title", field_type: "text"})

      params = %{
        "schema_id" => schema1.id,
        "id" => field.id,
        "field" => %{"name" => "test"}
      }

      conn = post(conn, "/admin/schemas/#{schema1.id}/fields/#{field.id}/update", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema1.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when schema is code-managed", %{conn: conn} do
      schema = create_schema(%{name: "posts", managed_by: "code"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      params = %{
        "schema_id" => schema.id,
        "id" => field.id,
        "field" => %{"name" => "updated"}
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/update", params)

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "code-managed"
    end

    test "handles update errors", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      params = %{
        "schema_id" => schema.id,
        "id" => field.id,
        "field" => %{
          # Invalid: empty name
          "name" => ""
        }
      }

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/update", params)

      # Should redirect with error
      assert redirected_to(conn) =~ "/admin/schemas/#{schema.id}/fields/#{field.id}/edit"
    end
  end

  describe "delete_confirm/2" do
    test "shows confirmation page for field deletion", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      conn = get(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/delete")

      assert html_response(conn, 200)
      assert conn.assigns.schema.id == schema.id
      assert conn.assigns.field.id == field.id
      assert conn.assigns.affected_contents == []
    end

    test "shows affected contents that have field filled", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      # Create content with field filled
      content1 = create_content(schema, %{to_string(field.id) => "Filled"})
      # Create content with empty field
      _content2 = create_content(schema, %{to_string(field.id) => ""})
      # Create content without field
      _content3 = create_content(schema, %{})

      conn = get(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/delete")

      assert html_response(conn, 200)
      assert length(conn.assigns.affected_contents) == 1
      assert List.first(conn.assigns.affected_contents).id == content1.id
    end

    test "redirects when schema not found", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      conn = get(conn, "/admin/schemas/99999/fields/#{field.id}/delete")

      assert redirected_to(conn) == "/admin/schemas/99999"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when field not found", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      conn = get(conn, "/admin/schemas/#{schema.id}/fields/99999/delete")

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when field does not belong to schema", %{conn: conn} do
      schema1 = create_schema(%{name: "posts"})
      schema2 = create_schema(%{name: "pages"})
      field = create_field(schema2, %{name: "title", field_type: "text"})

      conn = get(conn, "/admin/schemas/#{schema1.id}/fields/#{field.id}/delete")

      assert redirected_to(conn) == "/admin/schemas/#{schema1.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end
  end

  describe "delete/2" do
    test "deletes field successfully", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/delete")

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "title"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "deleted successfully"

      # Verify field was deleted
      assert Repo.get(Field, field.id) == nil
    end

    test "removes field data from all content instances", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field1 = create_field(schema, %{name: "title", field_type: "text"})
      field2 = create_field(schema, %{name: "body", field_type: "text"})

      content =
        create_content(schema, %{
          to_string(field1.id) => "Title",
          to_string(field2.id) => "Body"
        })

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/#{field1.id}/delete")

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"

      # Verify field data was removed from content
      updated_content = Repo.get(Content, content.id)
      assert Map.has_key?(updated_content.field_values, to_string(field1.id)) == false
      assert updated_content.field_values[to_string(field2.id)] == "Body"
    end

    test "redirects when field not found", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/99999/delete")

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "redirects when field does not belong to schema", %{conn: conn} do
      schema1 = create_schema(%{name: "posts"})
      schema2 = create_schema(%{name: "pages"})
      field = create_field(schema2, %{name: "title", field_type: "text"})

      conn = post(conn, "/admin/schemas/#{schema1.id}/fields/#{field.id}/delete")

      assert redirected_to(conn) == "/admin/schemas/#{schema1.id}"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not found"
    end

    test "handles multiple content instances", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field = create_field(schema, %{name: "title", field_type: "text"})

      content1 = create_content(schema, %{to_string(field.id) => "Post 1"})
      content2 = create_content(schema, %{to_string(field.id) => "Post 2"})

      conn = post(conn, "/admin/schemas/#{schema.id}/fields/#{field.id}/delete")

      assert redirected_to(conn) == "/admin/schemas/#{schema.id}"

      # Verify field data removed from all content
      assert Map.has_key?(Repo.get(Content, content1.id).field_values, to_string(field.id)) ==
               false

      assert Map.has_key?(Repo.get(Content, content2.id).field_values, to_string(field.id)) ==
               false
    end
  end
end
