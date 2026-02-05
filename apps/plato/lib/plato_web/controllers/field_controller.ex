defmodule PlatoWeb.FieldController do
  use Phoenix.Controller, formats: [:html]
  import Ecto.Query

  def create(conn, %{"schema_id" => schema_id, "field" => field_params}) do
    attrs =
      field_params
      |> Map.put("schema_id", schema_id)
      |> normalize_field_params()
      |> extract_field_options()

    case Plato.Field.create(attrs, repo(conn)) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "Field '#{field.name}' added successfully!")
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to add field")
        |> redirect(to: "#{base_path(conn)}/schemas/#{schema_id}")
    end
  end

  defp normalize_field_params(%{"field_type" => "reference", "referenced_schema_id" => ""} = params) do
    Map.put(params, "referenced_schema_id", nil)
  end

  defp normalize_field_params(%{"field_type" => "text"} = params) do
    Map.put(params, "referenced_schema_id", nil)
  end

  defp normalize_field_params(params), do: params

  defp extract_field_options(%{"field_type" => "text"} = params) do
    # Extract multiline option
    options =
      case Map.get(params, "multiline") do
        "true" -> %{"multiline" => true}
        "on" -> %{"multiline" => true}
        _ -> %{}
      end

    # Remove temporary form fields and add options
    params
    |> Map.delete("multiline")
    |> Map.put("options", options)
  end

  defp extract_field_options(params) do
    # For non-text fields, just set empty options
    Map.put(params, "options", %{})
  end

  def delete_confirm(conn, %{"schema_id" => schema_id, "id" => field_id}) do
    schema = repo(conn).get(Plato.Schema, schema_id)
    field = repo(conn).get(Plato.Field, field_id) |> repo(conn).preload(:referenced_schema)

    if schema && field && field.schema_id == String.to_integer(schema_id) do
      # Get all content for this schema
      contents =
        repo(conn).all(
          from c in Plato.Content,
          where: c.schema_id == ^schema_id
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
          from c in Plato.Content,
          where: c.schema_id == ^schema_id
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
