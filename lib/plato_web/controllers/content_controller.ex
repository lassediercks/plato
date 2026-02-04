defmodule PlatoWeb.ContentController do
  use Phoenix.Controller, formats: [:html]

  def index(conn, _params) do
    schemas = Plato.Repo.all(Plato.Schema)
    contents =
      Plato.Repo.all(Plato.Content)
      |> Plato.Repo.preload(:schema)

    # Get count of content instances per schema
    content_counts =
      contents
      |> Enum.group_by(& &1.schema_id)
      |> Enum.map(fn {schema_id, contents} -> {schema_id, length(contents)} end)
      |> Map.new()

    render(conn, :index, schemas: schemas, contents: contents, content_counts: content_counts)
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
    schema = Plato.Repo.get(Plato.Schema, schema_id)

    # Check if schema is unique and already has content
    if schema && schema.unique do
      existing_content =
        Plato.Repo.get_by(Plato.Content, schema_id: schema_id)

      if existing_content do
        conn
        |> put_flash(:error, "This schema is unique and already has content. You can only create one instance.")
        |> redirect(to: "/content")
      else
        create_content(conn, schema_id, content_params)
      end
    else
      create_content(conn, schema_id, content_params)
    end
  end

  defp create_content(conn, schema_id, content_params) do
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
