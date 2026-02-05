defmodule PlatoWeb.SchemaController do
  use Phoenix.Controller, formats: [:html]
  import Ecto.Query

  def index(conn, _params) do
    schemas = repo(conn).all(Plato.Schema)
    render(conn, :index, schemas: schemas, base_path: base_path(conn))
  end

  def create(conn, %{"schema" => schema_params}) do
    case Plato.Schema.create(schema_params, repo(conn)) do
      {:ok, schema} ->
        conn
        |> put_flash(:info, "Schema '#{schema.name}' created successfully!")
        |> redirect(to: base_path(conn))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create schema")
        |> redirect(to: base_path(conn))
    end
  end

  def show(conn, %{"id" => id}) do
    case repo(conn).get(Plato.Schema, id) do
      nil ->
        conn
        |> put_flash(:error, "Schema not found")
        |> redirect(to: base_path(conn))

      schema ->
        fields_query = from(f in Plato.Field, order_by: [asc: f.position])
        schema = repo(conn).preload(schema, [fields: {fields_query, :referenced_schema}])
        all_schemas = repo(conn).all(Plato.Schema)
        render(conn, :show, schema: schema, all_schemas: all_schemas, base_path: base_path(conn))
    end
  end

  # Private helper to get repo from conn assigns
  defp repo(conn) do
    otp_app = conn.assigns[:plato_otp_app] || :plato

    otp_app
    |> Application.get_env(:plato, [])
    |> Keyword.get(:repo, Plato.Repo)
  end

  # Private helper to get base path from conn assigns
  defp base_path(conn) do
    conn.assigns[:plato_base_path] || "/"
  end
end
