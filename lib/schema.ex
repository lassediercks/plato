defmodule Plato.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          unique: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "schemas" do
    field(:name, :string)
    field(:unique, :boolean, default: false)
    has_many(:fields, Plato.Field)
    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a schema.
  """
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :unique])
    |> validate_required([:name])
  end

  @spec create(map(), module()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, repo \\ Plato.Repo) do
    %__MODULE__{}
    |> changeset(attrs)
    |> repo.insert()
  end
end
