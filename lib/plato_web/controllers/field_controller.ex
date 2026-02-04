defmodule PlatoWeb.FieldController do
  use Phoenix.Controller, formats: [:html]

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
end
