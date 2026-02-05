defmodule Plato.Field do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          field_type: String.t(),
          schema_id: integer(),
          referenced_schema_id: integer() | nil,
          options: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "fields" do
    field(:name, :string)
    field(:field_type, :string, default: "text")
    field(:options, :map, default: %{})
    belongs_to(:schema, Plato.Schema)
    belongs_to(:referenced_schema, Plato.Schema)
    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a field.
  """
  def changeset(field, attrs) do
    field
    |> cast(attrs, [:name, :schema_id, :field_type, :referenced_schema_id, :options])
    |> validate_required([:schema_id, :name])
    |> validate_inclusion(:field_type, ["text", "reference"])
    |> validate_options()
    |> validate_reference_schema()
    |> set_reference_name()
  end

  defp validate_options(changeset) do
    # Ecto.Changeset.cast already validates that :map type is a map
    # This function is here for any additional custom validations
    changeset
  end

  defp validate_reference_schema(changeset) do
    field_type = get_field(changeset, :field_type)
    referenced_schema_id = get_field(changeset, :referenced_schema_id)
    name = get_field(changeset, :name)
    is_new_record = changeset.data.__meta__.state == :built

    case field_type do
      "reference" when is_nil(referenced_schema_id) and (is_nil(name) or not is_new_record) ->
        # Require referenced_schema_id unless:
        # 1. It's a new record (insert) with an explicit name (forward reference)
        # Allow forward references only during initial creation with explicit name
        add_error(changeset, :referenced_schema_id, "must be set for reference fields")

      "text" when not is_nil(referenced_schema_id) ->
        add_error(changeset, :referenced_schema_id, "should not be set for text fields")

      _ ->
        changeset
    end
  end

  defp set_reference_name(changeset) do
    field_type = get_field(changeset, :field_type)
    name = get_field(changeset, :name)
    referenced_schema_id = get_field(changeset, :referenced_schema_id)

    case {field_type, name, referenced_schema_id} do
      {"reference", nil, id} when not is_nil(id) ->
        # Auto-generate name from referenced schema
        case Plato.Repo.get(Plato.Schema, id) do
          nil -> changeset
          schema -> put_change(changeset, :name, schema.name)
        end

      _ ->
        changeset
    end
  end

  @spec create(map(), module()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, repo \\ Plato.Repo) do
    %__MODULE__{}
    |> changeset(attrs)
    |> repo.insert()
  end
end
