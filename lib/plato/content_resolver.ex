defmodule Plato.ContentResolver do
  @moduledoc false
  # Internal module for resolving content field values

  @doc """
  Converts a Content struct with field_values map (keyed by field IDs)
  into a friendly map with field names as atom keys.

  ## Examples

      content = %Plato.Content{
        field_values: %{"1" => "Homepage", "2" => "3"},
        schema: %Plato.Schema{
          fields: [
            %Plato.Field{id: 1, name: "title", field_type: "text"},
            %Plato.Field{id: 2, name: "hero", field_type: "reference", referenced_schema_id: 2}
          ]
        }
      }

      resolve_fields(content, repo)
      #=> %{title: "Homepage", hero: %Plato.Content{...}}
  """
  @spec resolve_fields(Plato.Content.t(), module()) :: map()
  def resolve_fields(%Plato.Content{} = content, repo) do
    # Ensure schema and fields are preloaded
    content = repo.preload(content, schema: [fields: :referenced_schema])

    # Convert field values from ID-keyed map to name-keyed map
    content.schema.fields
    |> Enum.reduce(%{}, fn field, acc ->
      field_id_str = to_string(field.id)
      raw_value = Map.get(content.field_values, field_id_str)

      resolved_value = resolve_field_value(field, raw_value, repo)
      field_name_atom = String.to_atom(field.name)
      Map.put(acc, field_name_atom, resolved_value)
    end)
  end

  defp resolve_field_value(%{field_type: "text"}, value, _repo), do: value

  # Handle multiple references (array)
  defp resolve_field_value(%{field_type: "reference"}, value, repo) when is_list(value) do
    Enum.map(value, fn content_id_str ->
      resolve_single_reference(content_id_str, repo)
    end)
    |> Enum.reject(&is_nil/1)
  end

  # Handle single reference (string)
  defp resolve_field_value(%{field_type: "reference"}, content_id_str, repo)
       when is_binary(content_id_str) do
    resolve_single_reference(content_id_str, repo)
  end

  defp resolve_field_value(%{field_type: "reference"}, _value, _repo), do: nil

  # Extract common resolution logic
  defp resolve_single_reference(content_id_str, repo) do
    case Integer.parse(content_id_str) do
      {content_id, ""} ->
        case repo.get(Plato.Content, content_id) do
          nil ->
            nil

          content ->
            # Recursively resolve referenced content fields
            content
            |> repo.preload(schema: :fields)
            |> resolve_fields(repo)
        end

      _ ->
        nil
    end
  end

  @doc """
  Converts friendly field names to field IDs for storage.

  Takes attrs like %{title: "Homepage", hero_id: 3} and a schema,
  returns %{"1" => "Homepage", "2" => "3"} for database storage.
  """
  @spec prepare_field_values(map(), Plato.Schema.t()) :: map()
  def prepare_field_values(attrs, %Plato.Schema{} = schema) do
    schema.fields
    |> Enum.reduce(%{}, fn field, acc ->
      # Try both the field name and field name + "_id" for references
      field_name_atom = String.to_atom(field.name)
      field_name_id_atom = String.to_atom("#{field.name}_id")

      value =
        Map.get(attrs, field_name_atom) ||
          Map.get(attrs, field_name_id_atom) ||
          Map.get(attrs, field.name) ||
          Map.get(attrs, "#{field.name}_id")

      if value do
        # Convert to string for storage
        Map.put(acc, to_string(field.id), to_string(value))
      else
        acc
      end
    end)
  end
end
