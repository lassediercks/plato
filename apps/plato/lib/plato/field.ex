defmodule Plato.Field do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          field_type: String.t(),
          schema_id: integer(),
          referenced_schema_id: integer() | nil,
          options: map(),
          position: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "fields" do
    field(:name, :string)
    field(:field_type, :string, default: "text")
    field(:options, :map, default: %{})
    field(:position, :integer)
    belongs_to(:schema, Plato.Schema)
    belongs_to(:referenced_schema, Plato.Schema)
    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a field.

  Options:
    * `:otp_app` - The OTP app to check for storage configuration (required for image fields)
  """
  def changeset(field, attrs, opts \\ []) do
    field
    |> cast(attrs, [:name, :schema_id, :field_type, :referenced_schema_id, :options, :position])
    |> validate_required([:schema_id, :name])
    |> validate_inclusion(:field_type, ["text", "richtext", "reference", "image"])
    |> validate_options()
    |> validate_reference_schema()
    |> validate_image_field_requirements(opts)
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

      "richtext" when not is_nil(referenced_schema_id) ->
        add_error(changeset, :referenced_schema_id, "should not be set for richtext fields")

      _ ->
        changeset
    end
  end

  defp validate_image_field_requirements(changeset, opts) do
    field_type = get_field(changeset, :field_type)

    if field_type == "image" do
      otp_app = Keyword.get(opts, :otp_app)

      cond do
        is_nil(otp_app) ->
          add_error(changeset, :field_type, "cannot create image field without otp_app context")

        not storage_configured?(otp_app) ->
          add_error(
            changeset,
            :field_type,
            "image fields require S3 storage configuration. Please configure storage in your config file and install required dependencies (ex_aws, ex_aws_s3, hackney)"
          )

        not storage_dependencies_available?() ->
          add_error(
            changeset,
            :field_type,
            "image fields require ex_aws, ex_aws_s3, and hackney packages. Please add them to your mix.exs dependencies"
          )

        true ->
          changeset
      end
    else
      changeset
    end
  end

  defp storage_configured?(otp_app) do
    Plato.Storage.Config.configured?(otp_app)
  end

  defp storage_dependencies_available? do
    Code.ensure_loaded?(ExAws) and
      Code.ensure_loaded?(ExAws.S3) and
      Code.ensure_loaded?(:hackney)
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

  @spec create(map(), module(), keyword()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, repo \\ Plato.Repo, opts \\ []) do
    # If position is not provided, calculate the next position for this schema
    attrs_with_position =
      if Map.has_key?(attrs, :position) or Map.has_key?(attrs, "position") do
        attrs
      else
        schema_id = attrs[:schema_id] || attrs["schema_id"]

        # Only calculate position if schema_id is present
        if schema_id do
          # Convert to integer if it's a string
          schema_id = if is_binary(schema_id), do: String.to_integer(schema_id), else: schema_id

          max_position =
            from(f in __MODULE__,
              where: f.schema_id == ^schema_id,
              select: max(f.position)
            )
            |> repo.one()

          next_position = (max_position || 0) + 1

          # Detect whether the attrs map uses atom or string keys
          # Use the same key type to avoid mixed keys
          position_key = if Map.has_key?(attrs, :schema_id), do: :position, else: "position"
          Map.put(attrs, position_key, next_position)
        else
          attrs
        end
      end

    %__MODULE__{}
    |> changeset(attrs_with_position, opts)
    |> repo.insert()
  end
end
