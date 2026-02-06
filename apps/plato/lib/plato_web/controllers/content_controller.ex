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

  def create(conn, params) do
    schema_id = Map.get(params, "schema_id")
    content_params = Map.get(params, "content", %{})
    content_files = Map.get(params, "content_files", %{})

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
        create_content(conn, schema_id, content_params, content_files)
      end
    else
      create_content(conn, schema_id, content_params, content_files)
    end
  end

  defp create_content(conn, schema_id, content_params, content_files) do
    schema = repo(conn).get(Plato.Schema, schema_id) |> repo(conn).preload(:fields)
    otp_app = conn.assigns[:plato_otp_app]

    # Start with regular field values
    field_values =
      content_params
      |> Map.delete("schema_id")
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        Map.put(acc, key, value)
      end)

    # Handle file uploads for image fields
    field_values =
      case handle_image_uploads(content_files, schema, otp_app) do
        {:ok, image_values} -> Map.merge(field_values, image_values)
        {:error, reason} ->
          conn
          |> put_flash(:error, "Image upload failed: #{reason}")
          |> redirect(to: "#{base_path(conn)}/content/new?schema_id=#{schema_id}")
          |> halt()

          field_values
      end

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

  defp handle_image_uploads(content_files, schema, otp_app) do
    storage_config = Plato.Storage.Config.get(otp_app)

    if Enum.empty?(content_files) do
      {:ok, %{}}
    else
      # Get image fields from schema
      image_fields = Enum.filter(schema.fields, fn field -> field.field_type == "image" end)

      # Process each uploaded file
      image_values =
        Enum.reduce_while(content_files, %{}, fn {field_id, upload}, acc ->
          field = Enum.find(image_fields, fn f -> to_string(f.id) == field_id end)

          if field && upload && upload.path do
            # Generate storage path
            storage_path = generate_storage_path(otp_app, schema.name, field.name, upload.filename)

            # Get adapter and upload file
            adapter = Keyword.get(storage_config, :adapter)

            case adapter.put(upload, storage_path, storage_config) do
              {:ok, _path} ->
                # Generate signed URL
                case adapter.get_url(storage_path, storage_config) do
                  {:ok, url} ->
                    # Store image metadata
                    image_data = %{
                      "url" => url,
                      "storage_path" => storage_path,
                      "filename" => upload.filename,
                      "content_type" => upload.content_type,
                      "size_bytes" => File.stat!(upload.path).size
                    }

                    {:cont, Map.put(acc, field_id, image_data)}

                  {:error, reason} ->
                    {:halt, {:error, "Failed to generate URL: #{inspect(reason)}"}}
                end

              {:error, reason} ->
                {:halt, {:error, "Failed to upload file: #{inspect(reason)}"}}
            end
          else
            {:cont, acc}
          end
        end)

      case image_values do
        {:error, _} = error -> error
        values -> {:ok, values}
      end
    end
  end

  defp generate_storage_path(otp_app, schema_name, field_name, filename) do
    timestamp = System.system_time(:second)
    random = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    safe_filename = String.replace(filename, ~r/[^a-zA-Z0-9._-]/, "_")

    "#{otp_app}/#{schema_name}/#{field_name}/#{timestamp}_#{random}_#{safe_filename}"
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

  def update(conn, params) do
    id = Map.get(params, "id")
    content_params = Map.get(params, "content", %{})
    content_files = Map.get(params, "content_files", %{})

    case repo(conn).get(Plato.Content, id) do
      nil ->
        conn
        |> put_flash(:error, "Content not found")
        |> redirect(to: "#{base_path(conn)}/content")

      content ->
        content = repo(conn).preload(content, [:schema])
        schema = repo(conn).preload(content.schema, :fields)
        otp_app = conn.assigns[:plato_otp_app]

        # Start with existing field values
        field_values = content.field_values || %{}

        # Merge in updated text/reference field values
        field_values =
          content_params
          |> Map.delete("schema_id")
          |> Enum.reduce(field_values, fn {key, value}, acc ->
            Map.put(acc, key, value)
          end)

        # Handle new image uploads
        field_values =
          case handle_image_uploads(content_files, schema, otp_app) do
            {:ok, image_values} -> Map.merge(field_values, image_values)
            {:error, reason} ->
              conn
              |> put_flash(:error, "Image upload failed: #{reason}")
              |> redirect(to: "#{base_path(conn)}/content/#{id}/edit")
              |> halt()

              field_values
          end

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
