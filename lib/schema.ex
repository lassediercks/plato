defmodule Plato.Schema do
  @moduledoc """
  Schema definition for content types.

  Schemas define the structure of content types in Plato CMS. Each schema has a name,
  can be marked as unique (singleton), and contains field definitions.

  ## Managed By

  Schemas can be managed in two ways:

  - `"ui"` - Created and managed through the admin interface (default)
  - `"code"` - Defined in code using `Plato.SchemaBuilder` and synced via `Plato.sync_schemas/2`

  Code-managed schemas appear as read-only in the admin UI.

  ## Fields

  - `name` - Unique schema identifier (e.g., "homepage", "blog-post")
  - `unique` - If true, only one content instance allowed (default: false)
  - `managed_by` - Source of schema management ("ui" or "code")
  - `fields` - Associated field definitions

  This module is primarily used internally. Use the `Plato` module and
  `Plato.SchemaBuilder` for schema operations instead.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          unique: boolean(),
          managed_by: String.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "schemas" do
    field(:name, :string)
    field(:unique, :boolean, default: false)
    field(:managed_by, :string, default: "ui")
    has_many(:fields, Plato.Field)
    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a schema.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :unique, :managed_by])
    |> validate_required([:name])
    |> validate_inclusion(:managed_by, ["ui", "code"])
    |> unique_constraint(:name)
  end

  @spec create(map(), module()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, repo \\ Plato.Repo) do
    %__MODULE__{}
    |> changeset(attrs)
    |> repo.insert()
  end
end
