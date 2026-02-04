defmodule PlatoWeb.SchemaController do
  use Phoenix.Controller, formats: [:html]

  def index(conn, _params) do
    schemas = Plato.Repo.all(Plato.Schema)
    render(conn, :index, schemas: schemas)
  end

  def create(conn, %{"schema" => %{"name" => name}}) do
    case Plato.Schema.create(%{name: name}) do
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
    case Plato.Repo.get(Plato.Schema, id) do
      nil ->
        conn
        |> put_flash(:error, "Schema not found")
        |> redirect(to: "/")

      schema ->
        render(conn, :show, schema: schema)
    end
  end
end
