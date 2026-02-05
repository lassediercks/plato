defmodule Plato.TestHelpers do
  @moduledoc """
  Helper functions for creating test data.
  """

  alias Plato.{Schema, Field, Content, Repo}

  @doc """
  Creates a test schema with the given attributes.
  """
  def create_schema(attrs \\ %{}) do
    default_attrs = %{
      name: "test_schema_#{System.unique_integer([:positive])}",
      unique: false,
      managed_by: "ui"
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, schema} = Schema.create(attrs, Repo)
    schema
  end

  @doc """
  Creates a test field for the given schema.
  """
  def create_field(schema, attrs \\ %{}) do
    default_attrs = %{
      schema_id: schema.id,
      name: "test_field_#{System.unique_integer([:positive])}",
      field_type: "text"
    }

    attrs = Map.merge(default_attrs, attrs)
    {:ok, field} = Field.create(attrs, Repo)
    field
  end

  @doc """
  Creates test content for the given schema.
  """
  def create_content(schema, field_values \\ %{}) do
    attrs = %{
      schema_id: schema.id,
      field_values: field_values
    }

    {:ok, content} = Content.create(attrs, Repo)
    content
  end

  @doc """
  Creates a complete schema with fields and returns it preloaded.
  """
  def create_schema_with_fields(schema_attrs \\ %{}, field_definitions \\ []) do
    schema = create_schema(schema_attrs)

    _fields =
      Enum.map(field_definitions, fn field_def ->
        create_field(schema, field_def)
      end)

    Repo.preload(schema, :fields, force: true)
  end
end
