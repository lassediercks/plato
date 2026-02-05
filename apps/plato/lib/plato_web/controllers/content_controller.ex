defmodule PlatoWeb.ContentController do
  use Phoenix.Controller, formats: [:html]
  import Ecto.Query

  def index(conn, _params) do
    schemas = repo(conn).all(Plato.Schema)
    fields_query = from(f in Plato.Field, order_by: [asc: f.position])
    contents =
      repo(conn).all(Plato.Content)
      |> repo(conn).preload([schema: [fields: fields_query]])

    # Get count of content instances per schema
    content_counts =
      contents
      |> Enum.group_by(& &1.schema_id)
      |> Enum.map(fn {schema_id, contents} -> {schema_id, length(contents)} end)
      |> Map.new()

    # Extract title for each content
    contents_with_titles =
      contents
      |> Enum.map(fn content ->
        title = get_content_title(content, repo(conn))
        {content, title}
      end)

    render(conn, :index,
      schemas: schemas,
      contents_with_titles: contents_with_titles,
      content_counts: content_counts,
      base_path: base_path(conn))
  end

  # Private helper to extract title from content
  defp get_content_title(content, repo) do
    # Find field marked as_title or use first field
    title_field =
      Enum.find(content.schema.fields, fn field ->
        Map.get(field.options, "as_title") == true
      end) ||
      List.first(content.schema.fields)

    case title_field do
      nil ->
        nil

      field ->
        # Get field value from field_values map
        field_id_str = to_string(field.id)
        field_value = Map.get(content.field_values, field_id_str)

        # If it's a reference field, resolve it
        if field.field_type == "reference" && field_value do
          case repo.get(Plato.Content, field_value) do
            nil -> field_value
            referenced_content -> get_content_title(referenced_content, repo)
          end
        else
          field_value
        end
    end
  end

  def new(conn, %{"schema_id" => schema_id}) do
    case repo(conn).get(Plato.Schema, schema_id) do
      nil ->
        conn
        |> put_flash(:error, "Schema not found")
        |> redirect(to: "#{base_path(conn)}/content")

      schema ->
        fields_query = from(f in Plato.Field, order_by: [asc: f.position])
        schema = repo(conn).preload(schema, [fields: {fields_query, :referenced_schema}])
        all_contents = repo(conn).all(Plato.Content) |> repo(conn).preload(:schema)
        render(conn, :new, schema: schema, all_contents: all_contents, base_path: base_path(conn))
    end
  end

  def create(conn, %{"schema_id" => schema_id, "content" => content_params}) do
    schema = repo(conn).get(Plato.Schema, schema_id)

    # Check if schema is unique and already has content
    if schema && schema.unique do
      existing_content =
        repo(conn).get_by(Plato.Content, schema_id: schema_id)

      if existing_content do
        conn
        |> put_flash(:error, "This schema is unique and already has content. You can only create one instance.")
        |> redirect(to: "#{base_path(conn)}/content")
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

    case Plato.Content.create(attrs, repo(conn)) do
      {:ok, _content} ->
        conn
        |> put_flash(:info, "Content created successfully!")
        |> redirect(to: "#{base_path(conn)}/content")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create content")
        |> redirect(to: "#{base_path(conn)}/content/new?schema_id=#{schema_id}")
    end
  end

  def show(conn, %{"id" => id}) do
    case repo(conn).get(Plato.Content, id) do
      nil ->
        conn
        |> put_flash(:error, "Content not found")
        |> redirect(to: "#{base_path(conn)}/content")

      content ->
        fields_query = from(f in Plato.Field, order_by: [asc: f.position])
        content = repo(conn).preload(content, [schema: [fields: {fields_query, :referenced_schema}]])
        all_contents = repo(conn).all(Plato.Content) |> repo(conn).preload(:schema)
        render(conn, :show, content: content, all_contents: all_contents, base_path: base_path(conn))
    end
  end

  def edit(conn, %{"id" => id}) do
    case repo(conn).get(Plato.Content, id) do
      nil ->
        conn
        |> put_flash(:error, "Content not found")
        |> redirect(to: "#{base_path(conn)}/content")

      content ->
        fields_query = from(f in Plato.Field, order_by: [asc: f.position])
        content = repo(conn).preload(content, [schema: [fields: {fields_query, :referenced_schema}]])
        all_contents = repo(conn).all(Plato.Content) |> repo(conn).preload(:schema)
        render(conn, :edit, content: content, all_contents: all_contents, base_path: base_path(conn))
    end
  end

  def update(conn, %{"id" => id, "content" => content_params}) do
    case repo(conn).get(Plato.Content, id) do
      nil ->
        conn
        |> put_flash(:error, "Content not found")
        |> redirect(to: "#{base_path(conn)}/content")

      content ->
        field_values =
          content_params
          |> Map.delete("schema_id")
          |> Enum.reduce(%{}, fn {key, value}, acc ->
            Map.put(acc, key, value)
          end)

        attrs = %{field_values: field_values}

        case content |> Plato.Content.changeset(attrs) |> repo(conn).update() do
          {:ok, updated_content} ->
            conn
            |> put_flash(:info, "Content updated successfully!")
            |> redirect(to: "#{base_path(conn)}/content/#{updated_content.id}")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Failed to update content")
            |> redirect(to: "#{base_path(conn)}/content/#{id}/edit")
        end
    end
  end

  # Private helper to get repo from conn assigns
  defp repo(conn) do
    otp_app = conn.assigns[:plato_otp_app] || :plato

    otp_app
    |> Application.get_env(:plato, [])
    |> Keyword.get(:repo, Plato.Repo)
  end

  # Private helper to get base_path from conn assigns
  defp base_path(conn), do: conn.assigns[:plato_base_path] || "/"
end
