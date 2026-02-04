defmodule PlatoWeb.FieldController do
  use Phoenix.Controller, formats: [:html]
  import Ecto.Query

  def create(conn, %{"schema_id" => schema_id, "field" => field_params}) do
    attrs =
      field_params
      |> Map.put("schema_id", schema_id)
      |> normalize_field_params()

    case Plato.Field.create(attrs) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "Field '#{field.name}' added successfully!")
        |> redirect(to: "/schemas/#{schema_id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to add field")
        |> redirect(to: "/schemas/#{schema_id}")
    end
  end

  defp normalize_field_params(%{"field_type" => "reference", "referenced_schema_id" => ""} = params) do
    Map.put(params, "referenced_schema_id", nil)
  end

  defp normalize_field_params(%{"field_type" => "text"} = params) do
    Map.put(params, "referenced_schema_id", nil)
  end

  defp normalize_field_params(params), do: params

  def delete_confirm(conn, %{"schema_id" => schema_id, "id" => field_id}) do
    schema = Plato.Repo.get(Plato.Schema, schema_id)
    field = Plato.Repo.get(Plato.Field, field_id) |> Plato.Repo.preload(:referenced_schema)

    if schema && field && field.schema_id == String.to_integer(schema_id) do
      # Get all content for this schema
      contents =
        Plato.Repo.all(
          from c in Plato.Content,
          where: c.schema_id == ^schema_id
        )
        |> Plato.Repo.preload(:schema)

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
        affected_contents: affected_contents
      )
    else
      conn
      |> put_flash(:error, "Field or schema not found")
      |> redirect(to: "/schemas/#{schema_id}")
    end
  end

  def delete(conn, %{"schema_id" => schema_id, "id" => field_id}) do
    field = Plato.Repo.get(Plato.Field, field_id)

    if field && field.schema_id == String.to_integer(schema_id) do
      # Remove field data from all content instances
      contents =
        Plato.Repo.all(
          from c in Plato.Content,
          where: c.schema_id == ^schema_id
        )

      Enum.each(contents, fn content ->
        updated_field_values = Map.delete(content.field_values, to_string(field.id))

        content
        |> Plato.Content.changeset(%{field_values: updated_field_values})
        |> Plato.Repo.update()
      end)

      # Delete the field
      Plato.Repo.delete(field)

      conn
      |> put_flash(:info, "Field '#{field.name}' deleted successfully!")
      |> redirect(to: "/schemas/#{schema_id}")
    else
      conn
      |> put_flash(:error, "Field not found")
      |> redirect(to: "/schemas/#{schema_id}")
    end
  end
end
