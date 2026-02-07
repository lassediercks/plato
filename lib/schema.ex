defmodule Plato.Schema do
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
