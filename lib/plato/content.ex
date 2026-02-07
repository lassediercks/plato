defmodule Plato.Content do
  @moduledoc """
  Content schema representing content instances.

  Content stores field values as a JSONB map keyed by field IDs. Each content
  instance belongs to a schema and contains field data according to that schema's
  field definitions.

  This module is primarily used internally by Plato. Use the `Plato` module for
  content queries and management instead.

  ## Internal Structure

  Content is stored with:
  - `schema_id` - Reference to the schema this content belongs to
  - `field_values` - Map of field_id => value pairs stored as JSONB

  Field values are stored with string keys (field IDs) and can contain:
  - Simple strings for text fields
  - Maps for image fields (with url, storage_path, etc.)
  - Integer IDs for reference fields (resolved by ContentResolver)

  ## Example Field Values

      %{
        "1" => "Blog Post Title",
        "2" => "This is the post body...",
        "3" => 42,  # Author ID (reference field)
        "4" => %{    # Image field
          "url" => "...",
          "storage_path" => "...",
          "filename" => "..."
        }
      }
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          schema_id: integer(),
          field_values: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "contents" do
    belongs_to(:schema, Plato.Schema)
    field(:field_values, :map, default: %{})
    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for content.
  """
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:schema_id, :field_values])
    |> validate_required([:schema_id])
    |> foreign_key_constraint(:schema_id)
  end

  @spec create(map(), module()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, repo \\ Plato.Repo) do
    %__MODULE__{}
    |> changeset(attrs)
    |> repo.insert()
  end
end
