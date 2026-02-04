defmodule PlatoWeb.SchemaController do
  use Phoenix.Controller, formats: [:html]

  def index(conn, _params) do
    schemas = repo(conn).all(Plato.Schema)
    render(conn, :index, schemas: schemas)
  end

  def create(conn, %{"schema" => schema_params}) do
    case Plato.Schema.create(schema_params, repo(conn)) do
      {:ok, schema} ->
        conn
        |> put_flash(:info, "Schema '#{schema.name}' created successfully!")
        |> redirect(to: "/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create schema")
        |> redirect(to: "/")
    end
  end

  def show(conn, %{"id" => id}) do
    case repo(conn).get(Plato.Schema, id) do
      nil ->
        conn
        |> put_flash(:error, "Schema not found")
        |> redirect(to: "/")

      schema ->
        schema = repo(conn).preload(schema, [fields: :referenced_schema])
        all_schemas = repo(conn).all(Plato.Schema)
        render(conn, :show, schema: schema, all_schemas: all_schemas)
    end
  end

  # Private helper to get repo from conn assigns
  defp repo(conn) do
    otp_app = conn.assigns[:plato_otp_app] || :plato

    otp_app
    |> Application.get_env(:plato, [])
    |> Keyword.get(:repo, Plato.Repo)
  end
end
