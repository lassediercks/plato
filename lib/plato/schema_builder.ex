defmodule Plato.SchemaBuilder do
  @moduledoc """
  DSL for defining CMS schemas in code.

  Schema definitions in code provide version control, consistency, and team collaboration
  benefits over UI-defined schemas. Schemas are marked as `managed_by: "code"` and
  displayed as read-only in the admin UI.

  ## Basic Usage

      defmodule MyApp.ContentSchemas do
        use Plato.SchemaBuilder

        schema "homepage", unique: true do
          field :title, :text
          field :tagline, :text, multiline: true
        end

        schema "blog-post" do
          field :title, :text
          field :slug, :text
          field :excerpt, :text, multiline: true
          field :body, :text, multiline: true
          field :author, :reference, to: "author"
        end

        schema "author" do
          field :name, :text
          field :email, :text
          field :bio, :text, multiline: true
        end
      end

  ## Syncing to Database

  Sync schemas on application startup in `application.ex`:

      def start(_type, _args) do
        children = [MyApp.Repo, ...]
        {:ok, pid} = Supervisor.start_link(children, opts)

        # Sync after repo starts
        Plato.sync_schemas(MyApp.ContentSchemas, otp_app: :my_app)
        {:ok, pid}
      end

  Or use a migration for one-time sync:

      defmodule MyApp.Repo.Migrations.SyncCMSSchemas do
        use Ecto.Migration

        def up do
          Plato.sync_schemas(MyApp.ContentSchemas, repo: MyApp.Repo)
        end

        def down do
          # Schemas remain but can be manually deleted if needed
        end
      end

  ## Schema Options

  - `:unique` - Only one content instance allowed (default: `false`)

  Unique schemas are useful for singleton content like homepage, site settings,
  or global configuration.

  ## Field Types

  - `:text` - Single-line or multiline text input
  - `:image` - Image upload with S3 storage (requires S3 configuration)
  - `:reference` - Reference to another schema (one-to-one relationship)

  ## Field Options

  ### Text Fields

  - `:multiline` - Render as textarea instead of input (default: `false`)
    Textareas are 100% width, 250px height with vertical resizing

  ### Reference Fields

  - `:to` - Target schema name (required for reference fields)

  ### Field Options (All Types)

  - `:as_title` - Use this field as the display title in lists (default: first field)

  ## Complete Example

      defmodule MyApp.ContentSchemas do
        use Plato.SchemaBuilder

        # Singleton content
        schema "site-settings", unique: true do
          field :site_name, :text, as_title: true
          field :tagline, :text
          field :logo, :image
        end

        # Blog system
        schema "blog-post" do
          field :title, :text, as_title: true
          field :slug, :text
          field :excerpt, :text, multiline: true
          field :body, :text, multiline: true
          field :cover_image, :image
          field :author, :reference, to: "author"
          field :category, :reference, to: "category"
        end

        schema "author" do
          field :name, :text, as_title: true
          field :email, :text
          field :bio, :text, multiline: true
          field :avatar, :image
        end

        schema "category" do
          field :name, :text, as_title: true
          field :slug, :text
          field :description, :text, multiline: true
        end
      end

  ## Updating Schemas

  When you modify schema definitions, re-running `sync_schemas/2` will:
  - Create new schemas that don't exist
  - Update existing schemas (unique flag, field options)
  - Create new fields
  - Update field options on existing fields
  - Preserve existing content and field values

  **Note:** Sync does not delete schemas or fields. Remove them manually via the admin
  UI if needed.

  ## Image Fields

  Image fields require S3-compatible storage configuration. See `Plato.Storage.S3Adapter`
  for setup instructions. Without S3 configuration, image fields will not appear in the
  admin UI.
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

  ## Field Options

    * `:multiline` - Render text field as textarea (default: false)
    * `:to` - Referenced schema name (for reference fields only)

  ## Examples

      field :title, :text
      field :body, :text, multiline: true
      field :excerpt, :text, multiline: true
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
