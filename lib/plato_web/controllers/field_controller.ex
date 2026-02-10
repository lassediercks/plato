defmodule PlatoWeb.FieldController do
  use Phoenix.Controller, formats: [:html]
  import Ecto.Query

  def create(conn, %{"schema_id" => schema_id, "field" => field_params}) do
    attrs =
      field_params
      |> Map.put("schema_id", schema_id)
      |> normalize_field_params()
      |> extract_field_options()

    case Plato.Field.create(attrs, repo(conn), otp_app: otp_app(conn)) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "Field '#{field.name}' added successfully!")
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")

      {:error, changeset} ->
        error_message =
          case changeset.errors[:field_type] do
            {msg, _} -> msg
            nil -> "Failed to add field"
          end

        conn
        |> put_flash(:error, error_message)
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")
    end
  end

  def reorder(conn, %{"schema_id" => _schema_id, "field_ids" => field_ids}) do
    # Update position for each field based on the order in the array
    Enum.with_index(field_ids, 1)
    |> Enum.each(fn {field_id, position} ->
      case repo(conn).get(Plato.Field, field_id) do
        nil ->
          :ok

        field ->
          field
          |> Plato.Field.changeset(%{position: position}, otp_app: otp_app(conn))
          |> repo(conn).update()
      end
    end)

    json(conn, %{success: true})
  end

  def edit(conn, %{"schema_id" => schema_id, "id" => field_id}) do
    schema = repo(conn).get(Plato.Schema, schema_id)
    field = repo(conn).get(Plato.Field, field_id) |> repo(conn).preload(:referenced_schema)
    all_schemas = repo(conn).all(Plato.Schema)

    cond do
      !schema || !field || field.schema_id != String.to_integer(schema_id) ->
        conn
        |> put_flash(:error, "Field or schema not found")
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")

      schema.managed_by == "code" ->
        conn
        |> put_flash(:error, "Cannot edit fields in code-managed schemas")
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")

      true ->
        render(conn, :edit,
          schema: schema,
          field: field,
          all_schemas: all_schemas,
          base_path: base_path(conn)
        )
    end
  end

  def update(conn, %{"schema_id" => schema_id, "id" => field_id, "field" => field_params}) do
    field = repo(conn).get(Plato.Field, field_id) |> repo(conn).preload(:schema)

    cond do
      !field || field.schema_id != String.to_integer(schema_id) ->
        conn
        |> put_flash(:error, "Field not found")
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")

      field.schema.managed_by == "code" ->
        conn
        |> put_flash(:error, "Cannot update fields in code-managed schemas")
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")

      true ->
        attrs =
          field_params
          |> normalize_field_params()
          |> extract_field_options_for_update(field)

        case field
             |> Plato.Field.changeset(attrs, otp_app: otp_app(conn))
             |> repo(conn).update() do
          {:ok, _field} ->
            conn
            |> put_flash(:info, "Field updated successfully!")
            |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")

          {:error, changeset} ->
            error_message =
              case changeset.errors[:field_type] do
                {msg, _} -> msg
                nil -> "Failed to update field"
              end

            conn
            |> put_flash(:error, error_message)
            |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}/fields/#{field_id}/edit")
        end
    end
  end

  defp normalize_field_params(
         %{"field_type" => "reference", "referenced_schema_id" => ""} = params
       ) do
    Map.put(params, "referenced_schema_id", nil)
  end

  defp normalize_field_params(%{"field_type" => "text"} = params) do
    Map.put(params, "referenced_schema_id", nil)
  end

  defp normalize_field_params(params), do: params

  defp extract_field_options(%{"field_type" => "text"} = params) do
    # Extract multiline and as_title options
    options = %{}

    options =
      case Map.get(params, "multiline") do
        "true" -> Map.put(options, "multiline", true)
        "on" -> Map.put(options, "multiline", true)
        _ -> options
      end

    options =
      case Map.get(params, "as_title") do
        "true" -> Map.put(options, "as_title", true)
        "on" -> Map.put(options, "as_title", true)
        _ -> options
      end

    # Remove temporary form fields and add options
    params
    |> Map.delete("multiline")
    |> Map.delete("as_title")
    |> Map.put("options", options)
  end

  defp extract_field_options(%{"field_type" => "reference"} = params) do
    # Extract multiple and as_title options for reference fields
    options = %{}

    options =
      case Map.get(params, "multiple") do
        "true" -> Map.put(options, "multiple", true)
        "on" -> Map.put(options, "multiple", true)
        _ -> options
      end

    options =
      case Map.get(params, "as_title") do
        "true" -> Map.put(options, "as_title", true)
        "on" -> Map.put(options, "as_title", true)
        _ -> options
      end

    params
    |> Map.delete("multiple")
    |> Map.delete("as_title")
    |> Map.put("options", options)
  end

  defp extract_field_options(params) do
    # Extract as_title option for non-text, non-reference fields
    options = %{}

    options =
      case Map.get(params, "as_title") do
        "true" -> Map.put(options, "as_title", true)
        "on" -> Map.put(options, "as_title", true)
        _ -> options
      end

    params
    |> Map.delete("as_title")
    |> Map.put("options", options)
  end

  defp extract_field_options_for_update(params, field) do
    # Similar to extract_field_options but for updates
    options = %{}

    # Handle as_title for all field types
    options =
      case Map.get(params, "as_title") do
        "true" -> Map.put(options, "as_title", true)
        "on" -> Map.put(options, "as_title", true)
        _ -> options
      end

    # Handle multiline for text fields
    options =
      if field.field_type == "text" do
        case Map.get(params, "multiline") do
          "true" -> Map.put(options, "multiline", true)
          "on" -> Map.put(options, "multiline", true)
          _ -> options
        end
      else
        options
      end

    # Handle multiple for reference fields
    options =
      if field.field_type == "reference" do
        case Map.get(params, "multiple") do
          "true" -> Map.put(options, "multiple", true)
          "on" -> Map.put(options, "multiple", true)
          _ -> options
        end
      else
        options
      end

    params
    |> Map.delete("multiline")
    |> Map.delete("multiple")
    |> Map.delete("as_title")
    |> Map.put("options", options)
  end

  def delete_confirm(conn, %{"schema_id" => schema_id, "id" => field_id}) do
    schema = repo(conn).get(Plato.Schema, schema_id)
    field = repo(conn).get(Plato.Field, field_id) |> repo(conn).preload(:referenced_schema)

    if schema && field && field.schema_id == String.to_integer(schema_id) do
      # Get all content for this schema
      contents =
        repo(conn).all(
          from(c in Plato.Content,
            where: c.schema_id == ^schema_id
          )
        )
        |> repo(conn).preload(:schema)

      # Find contents that have this field filled
      affected_contents =
        contents
        |> Enum.filter(fn content ->
          field_value = Map.get(content.field_values, to_string(field.id))
          field_value && field_value != ""
        end)

      render(conn, :delete_confirm,
        schema: schema,
        field: field,
        affected_contents: affected_contents,
        base_path: base_path(conn)
      )
    else
      conn
      |> put_flash(:error, "Field or schema not found")
      |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")
    end
  end

  def delete(conn, %{"schema_id" => schema_id, "id" => field_id}) do
    field = repo(conn).get(Plato.Field, field_id)

    if field && field.schema_id == String.to_integer(schema_id) do
      # Remove field data from all content instances
      contents =
        repo(conn).all(
          from(c in Plato.Content,
            where: c.schema_id == ^schema_id
          )
        )

      Enum.each(contents, fn content ->
        updated_field_values = Map.delete(content.field_values, to_string(field.id))

        content
        |> Plato.Content.changeset(%{field_values: updated_field_values})
        |> repo(conn).update()
      end)

      # Delete the field
      repo(conn).delete(field)

      conn
      |> put_flash(:info, "Field '#{field.name}' deleted successfully!")
      |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")
    else
      conn
      |> put_flash(:error, "Field not found")
      |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")
    end
  end

  # Private helper to get otp_app from conn assigns
  defp otp_app(conn), do: conn.assigns[:plato_otp_app] || :plato

  # Private helper to get repo from conn assigns
  defp repo(conn) do
    otp_app(conn)
    |> Application.get_env(:plato, [])
    |> Keyword.get(:repo, Plato.Repo)
  end

  # Private helper to get base_path from conn assigns
  defp base_path(conn) do
    # Return empty string for root path to avoid double slashes in URLs
    case conn.assigns[:plato_base_path] do
      nil -> ""
      "/" -> ""
      path -> path
    end
  end
end
