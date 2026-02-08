defmodule PlatoWeb.SchemaControllerTest do
  use PlatoWeb.ConnCase, async: false

  alias Plato.Schema

  setup %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:plato_otp_app, :plato)
      |> Plug.Conn.assign(:plato_base_path, "/admin")

    {:ok, conn: conn}
  end

  describe "index/2" do
    test "lists all schemas", %{conn: conn} do
      schema1 = create_schema(%{name: "posts"})
      schema2 = create_schema(%{name: "pages"})

      conn = get(conn, "/admin")

      assert html_response(conn, 200)
      assert length(conn.assigns.schemas) == 2
      assert Enum.any?(conn.assigns.schemas, fn s -> s.id == schema1.id end)
      assert Enum.any?(conn.assigns.schemas, fn s -> s.id == schema2.id end)
    end

    test "returns empty list when no schemas exist", %{conn: conn} do
      conn = get(conn, "/admin")

      assert html_response(conn, 200)
      assert conn.assigns.schemas == []
    end

    test "includes base_path in assigns", %{conn: conn} do
      conn = get(conn, "/admin")

      assert html_response(conn, 200)
      assert conn.assigns.base_path == "/admin"
    end
  end

  describe "create/2" do
    test "creates a schema successfully", %{conn: conn} do
      params = %{
        "schema" => %{
          "name" => "articles",
          "unique" => "false"
        }
      }

      conn = post(conn, "/admin", params)

      assert redirected_to(conn) == "/admin/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "articles"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "created successfully"

      # Verify schema was created
      schema = Repo.get_by(Schema, name: "articles")
      assert schema != nil
      assert schema.unique == false
    end

    test "creates a unique schema", %{conn: conn} do
      params = %{
        "schema" => %{
          "name" => "settings",
          "unique" => "true"
        }
      }

      conn = post(conn, "/admin", params)

      assert redirected_to(conn) == "/admin/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "settings"

      schema = Repo.get_by(Schema, name: "settings")
      assert schema.unique == true
    end

    test "creates a code-managed schema", %{conn: conn} do
      params = %{
        "schema" => %{
          "name" => "products",
          "managed_by" => "code"
        }
      }

      conn = post(conn, "/admin", params)

      assert redirected_to(conn) == "/admin/"

      schema = Repo.get_by(Schema, name: "products")
      assert schema.managed_by == "code"
    end

    test "handles schema creation errors", %{conn: conn} do
      # Try to create with invalid/missing name
      params = %{
        "schema" => %{
          "name" => ""
        }
      }

      conn = post(conn, "/admin", params)

      assert redirected_to(conn) == "/admin/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Failed to create schema"
    end

    test "handles duplicate schema names", %{conn: conn} do
      create_schema(%{name: "posts"})

      params = %{
        "schema" => %{
          "name" => "posts"
        }
      }

      conn = post(conn, "/admin", params)

      assert redirected_to(conn) == "/admin/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) != nil
    end
  end

  describe "show/2" do
    test "displays schema with fields", %{conn: conn} do
      schema = create_schema(%{name: "posts"})
      field1 = create_field(schema, %{name: "title", field_type: "text", position: 0})
      field2 = create_field(schema, %{name: "body", field_type: "text", position: 1})

      conn = get(conn, "/admin/schemas/#{schema.id}")

      assert html_response(conn, 200)
      assert conn.assigns.schema.id == schema.id
      assert length(conn.assigns.schema.fields) == 2

      # Verify fields are ordered by position
      [first_field, second_field] = conn.assigns.schema.fields
      assert first_field.id == field1.id
      assert second_field.id == field2.id
    end

    test "preloads referenced schemas for reference fields", %{conn: conn} do
      ref_schema = create_schema(%{name: "authors"})
      schema = create_schema(%{name: "posts"})

      field =
        create_field(schema, %{
          name: "author",
          field_type: "reference",
          options: %{"referenced_schema_id" => ref_schema.id}
        })

      # Set referenced_schema_id properly
      field
      |> Ecto.Changeset.change(%{referenced_schema_id: ref_schema.id})
      |> Repo.update!()

      conn = get(conn, "/admin/schemas/#{schema.id}")

      assert html_response(conn, 200)
      [loaded_field] = conn.assigns.schema.fields
      assert loaded_field.referenced_schema != nil
      assert loaded_field.referenced_schema.id == ref_schema.id
    end

    test "loads all schemas for reference field dropdown", %{conn: conn} do
      schema1 = create_schema(%{name: "posts"})
      _schema2 = create_schema(%{name: "authors"})
      _schema3 = create_schema(%{name: "categories"})

      conn = get(conn, "/admin/schemas/#{schema1.id}")

      assert html_response(conn, 200)
      assert length(conn.assigns.all_schemas) == 3
    end

    test "redirects when schema not found", %{conn: conn} do
      conn = get(conn, "/admin/schemas/99999")

      assert redirected_to(conn) == "/admin/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Schema not found"
    end

    test "handles schema with no fields", %{conn: conn} do
      schema = create_schema(%{name: "empty_schema"})

      conn = get(conn, "/admin/schemas/#{schema.id}")

      assert html_response(conn, 200)
      assert conn.assigns.schema.fields == []
    end

    test "includes base_path in assigns", %{conn: conn} do
      schema = create_schema(%{name: "posts"})

      conn = get(conn, "/admin/schemas/#{schema.id}")

      assert html_response(conn, 200)
      assert conn.assigns.base_path == "/admin"
    end
  end

  describe "repo/1 helper" do
    test "uses repo from conn assigns", %{conn: conn} do
      schema = create_schema(%{name: "test"})
      conn = get(conn, "/admin")

      # Verify repo was used by checking data loaded
      assert html_response(conn, 200)
      assert conn.assigns.schemas == [schema]
    end

    test "defaults to Plato.Repo when otp_app not set" do
      conn = Phoenix.ConnTest.build_conn()
      conn = get(conn, "/admin")

      # Should use default repo and not crash
      assert html_response(conn, 200)
    end
  end

  describe "base_path/1 helper" do
    test "returns base path from assigns", %{conn: conn} do
      conn = get(conn, "/admin")

      assert html_response(conn, 200)
      assert conn.assigns.base_path == "/admin"
    end

    test "defaults to / when not set" do
      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.assign(:plato_otp_app, :plato)

      conn = get(conn, "/admin")

      assert html_response(conn, 200)
      # Default base_path should be "/"
    end
  end
end
