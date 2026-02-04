defmodule PlatoWeb.ContentController do
  use Phoenix.Controller, formats: [:html]

  def index(conn, _params) do
    schemas = Plato.Repo.all(Plato.Schema)
    contents =
      Plato.Repo.all(Plato.Content)
      |> Plato.Repo.preload(:schema)

    render(conn, :index, schemas: schemas, contents: contents)
  end

  def new(conn, %{"schema_id" => schema_id}) do
    case Plato.Repo.get(Plato.Schema, schema_id) do
      nil ->
        conn
        |> put_flash(:error, "Schema not found")
        |> redirect(to: "/content")

      schema ->
        schema = Plato.Repo.preload(schema, [fields: :referenced_schema])
        all_contents = Plato.Repo.all(Plato.Content) |> Plato.Repo.preload(:schema)
        render(conn, :new, schema: schema, all_contents: all_contents)
    end
  end

  def create(conn, %{"schema_id" => schema_id, "content" => content_params}) do
    field_values =
      content_params
      |> Map.delete("schema_id")
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        # Convert field IDs to strings and store values
        Map.put(acc, key, value)
      end)

    attrs = %{
      schema_id: schema_id,
      field_values: field_values
    }

    case Plato.Content.create(attrs) do
      {:ok, _content} ->
        conn
        |> put_flash(:info, "Content created successfully!")
        |> redirect(to: "/content")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create content")
        |> redirect(to: "/content/new?schema_id=#{schema_id}")
    end
  end

  def show(conn, %{"id" => id}) do
    case Plato.Repo.get(Plato.Content, id) do
      nil ->
        conn
        |> put_flash(:error, "Content not found")
        |> redirect(to: "/content")

      content ->
        content = Plato.Repo.preload(content, [schema: [fields: :referenced_schema]])
        all_contents = Plato.Repo.all(Plato.Content) |> Plato.Repo.preload(:schema)
        render(conn, :show, content: content, all_contents: all_contents)
    end
  end
end
