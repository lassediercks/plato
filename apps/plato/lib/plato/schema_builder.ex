defmodule Plato.SchemaBuilder do
  @moduledoc """
  DSL for defining CMS schemas in code.

  ## Example

      defmodule MyApp.ContentSchemas do
        use Plato.SchemaBuilder

        schema "login-header", unique: true do
          field :title, :text
          field :tagline, :text
        end

        schema "blog-post" do
          field :title, :text
          field :body, :text
          field :author, :reference, to: "author"
        end

        schema "author" do
          field :name, :text
          field :bio, :text
        end
      end

  Then sync to database:

      Plato.sync_schemas(MyApp.ContentSchemas, otp_app: :my_app)

  Or in a migration:

      defmodule MyApp.Repo.Migrations.SyncCMSSchemas do
        use Ecto.Migration

        def up do
          Plato.sync_schemas(MyApp.ContentSchemas, repo: MyApp.Repo)
        end

        def down do
          # Schemas will remain but can be manually deleted if needed
        end
      end
  """

  defmacro __using__(_opts) do
    quote do
      import Plato.SchemaBuilder
      Module.register_attribute(__MODULE__, :schemas, accumulate: true)
      @before_compile Plato.SchemaBuilder
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __plato_schemas__ do
        @schemas
      end
    end
  end

  @doc """
  Defines a schema with fields.

  ## Options

    * `:unique` - Whether only one instance of this schema can exist (default: false)

  ## Examples

      schema "homepage", unique: true do
        field :title, :text
        field :hero_image, :reference, to: "image"
      end
  """
  defmacro schema(name, opts \\ [], do: block) do
    quote do
      @current_schema_name unquote(name)
      @current_schema_opts unquote(opts)
      @current_schema_fields []
      unquote(block)

      @schemas %{
        name: @current_schema_name,
        unique: Keyword.get(@current_schema_opts, :unique, false),
        fields: Enum.reverse(@current_schema_fields)
      }

      Module.delete_attribute(__MODULE__, :current_schema_name)
      Module.delete_attribute(__MODULE__, :current_schema_opts)
      Module.delete_attribute(__MODULE__, :current_schema_fields)
    end
  end

  @doc """
  Defines a field within a schema.

  ## Field Types

    * `:text` - Text field
    * `:reference` - Reference to another schema (requires `to: "schema_name"` option)

  ## Examples

      field :title, :text
      field :author, :reference, to: "author"
  """
  defmacro field(name, type, opts \\ []) do
    quote do
      field_def = %{
        name: to_string(unquote(name)),
        type: unquote(type),
        opts: unquote(opts)
      }

      @current_schema_fields [field_def | @current_schema_fields]
    end
  end
end
