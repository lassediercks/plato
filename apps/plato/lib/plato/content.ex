defmodule Plato.Content do
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
