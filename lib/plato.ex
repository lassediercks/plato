defmodule Plato do
  @moduledoc """
  Plato CMS - A schema-driven content management system for Phoenix.

  ## Configuration

  In your config.exs:

      config :my_app, :plato,
        repo: MyApp.Repo

  Or configure a default:

      config :plato,
        default_otp_app: :my_app

  ## Usage

  Query content by schema name:

      # Get unique content (for singleton schemas like "homepage")
      {:ok, homepage} = Plato.get_content("homepage", otp_app: :my_app)

      # Get all content for a schema
      {:ok, blog_posts} = Plato.list_content("blog_post", otp_app: :my_app)

      # Get specific content by ID
      {:ok, post} = Plato.get_content_by_id(1, otp_app: :my_app)

  ## Field Access

  Content returns a map with field names as keys:

      homepage.title
      #=> "Welcome to My Site"

      homepage.hero_image
      #=> %{url: "...", alt_text: "..."} (resolved referenced content)
  """

  import Ecto.Query
  alias Plato.{Content, Schema, ContentResolver}

  @type content_map :: %{atom() => String.t() | map() | nil}
  @type opts :: [otp_app: atom(), repo: module()]

  @doc """
  Get unique content by schema name.

  Returns `{:ok, content_map}` if found, `{:error, reason}` otherwise.
  Works only for schemas marked as `unique: true`.

  ## Examples

      Plato.get_content("homepage", otp_app: :my_app)
      # => {:ok, %{title: "Welcome", tagline: "...", hero: %{...}}}

      Plato.get_content("nonexistent", otp_app: :my_app)
      # => {:error, :schema_not_found}
  """
  @spec get_content(String.t(), opts()) :: {:ok, content_map()} | {:error, atom()}
  def get_content(schema_name, opts \\ []) do
    repo = get_repo(opts)

    with {:ok, schema} <- get_schema_by_name(schema_name, repo),
         {:ok, content} <- get_unique_content(schema, repo) do
      resolved = ContentResolver.resolve_fields(content, repo)
      {:ok, resolved}
    end
  end

  @doc """
  Get unique content by schema name, raises on error.

  ## Examples

      Plato.get_content!("homepage", otp_app: :my_app)
      # => %{title: "Welcome", tagline: "..."}
  """
  @spec get_content!(String.t(), opts()) :: content_map()
  def get_content!(schema_name, opts \\ []) do
    case get_content(schema_name, opts) do
      {:ok, content} -> content
      {:error, reason} -> raise "Failed to get content for '#{schema_name}': #{reason}"
    end
  end

  @doc """
  List all content instances for a schema.

  ## Examples

      Plato.list_content("blog_post", otp_app: :my_app)
      # => {:ok, [
      #      %{title: "Post 1", body: "...", author: %{name: "John"}},
      #      %{title: "Post 2", body: "...", author: %{name: "Jane"}}
      #    ]}
  """
  @spec list_content(String.t(), opts()) :: {:ok, [content_map()]} | {:error, atom()}
  def list_content(schema_name, opts \\ []) do
    repo = get_repo(opts)

    with {:ok, schema} <- get_schema_by_name(schema_name, repo) do
      contents =
        from(c in Content, where: c.schema_id == ^schema.id)
        |> repo.all()
        |> Enum.map(&ContentResolver.resolve_fields(&1, repo))

      {:ok, contents}
    end
  end

  @doc """
  Get content by database ID.

  ## Examples

      Plato.get_content_by_id(1, otp_app: :my_app)
      # => {:ok, %{title: "My Post", body: "..."}}
  """
  @spec get_content_by_id(integer(), opts()) :: {:ok, content_map()} | {:error, atom()}
  def get_content_by_id(id, opts \\ []) do
    repo = get_repo(opts)

    case repo.get(Content, id) do
      nil ->
        {:error, :content_not_found}

      content ->
        resolved = ContentResolver.resolve_fields(content, repo)
        {:ok, resolved}
    end
  end

  @doc """
  Get content by matching a field value.

  Finds content within a schema where a specific field matches a given value.
  Useful for slug-based lookups, email searches, etc.

  ## Examples

      Plato.get_content_by_field("blog-post", "slug", "my-first-post", otp_app: :my_app)
      # => {:ok, %{title: "My First Post", slug: "my-first-post", body: "..."}}

      Plato.get_content_by_field("author", "email", "jane@example.com", otp_app: :my_app)
      # => {:ok, %{name: "Jane Doe", email: "jane@example.com", ...}}
  """
  @spec get_content_by_field(String.t(), String.t(), String.t(), opts()) ::
          {:ok, content_map()} | {:error, atom()}
  def get_content_by_field(schema_name, field_name, field_value, opts \\ []) do
    repo = get_repo(opts)

    with {:ok, schema} <- get_schema_by_name(schema_name, repo) do
      schema = repo.preload(schema, :fields)
      field = Enum.find(schema.fields, fn f -> f.name == field_name end)

      case field do
        nil ->
          {:error, :field_not_found}

        field ->
          field_id_str = to_string(field.id)

          query =
            from(c in Content,
              where: c.schema_id == ^schema.id,
              where: fragment("?->>? = ?", c.field_values, ^field_id_str, ^field_value)
            )

          case repo.one(query) do
            nil ->
              {:error, :content_not_found}

            content ->
              resolved = ContentResolver.resolve_fields(content, repo)
              {:ok, resolved}
          end
      end
    end
  end

  @doc """
  Create content for a schema.

  ## Examples

      Plato.create_content("blog_post", %{
        title: "My Post",
        body: "Content here",
        author_id: 1  # ID of another content instance
      }, otp_app: :my_app)
      # => {:ok, %{title: "My Post", body: "Content here", author: %{...}}}
  """
  @spec create_content(String.t(), map(), opts()) ::
          {:ok, content_map()} | {:error, Ecto.Changeset.t() | atom()}
  def create_content(schema_name, attrs, opts \\ []) do
    repo = get_repo(opts)

    with {:ok, schema} <- get_schema_by_name(schema_name, repo),
         schema <- repo.preload(schema, :fields) do
      field_values = ContentResolver.prepare_field_values(attrs, schema)

      case Content.create(%{schema_id: schema.id, field_values: field_values}, repo) do
        {:ok, content} ->
          resolved = ContentResolver.resolve_fields(content, repo)
          {:ok, resolved}

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  @doc """
  Update content by ID.

  ## Examples

      Plato.update_content(1, %{title: "Updated Title"}, otp_app: :my_app)
      # => {:ok, %{title: "Updated Title", ...}}
  """
  @spec update_content(integer(), map(), opts()) ::
          {:ok, content_map()} | {:error, Ecto.Changeset.t() | atom()}
  def update_content(content_id, attrs, opts \\ []) do
    repo = get_repo(opts)

    case repo.get(Content, content_id) do
      nil ->
        {:error, :content_not_found}

      content ->
        content = repo.preload(content, schema: :fields)
        new_field_values = ContentResolver.prepare_field_values(attrs, content.schema)
        # Merge new values with existing ones to preserve fields not being updated
        merged_field_values = Map.merge(content.field_values, new_field_values)

        case content
             |> Content.changeset(%{field_values: merged_field_values})
             |> repo.update() do
          {:ok, updated_content} ->
            resolved = ContentResolver.resolve_fields(updated_content, repo)
            {:ok, resolved}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Syncs code-defined schemas to the database.

  Reads schema definitions from a module using `Plato.SchemaBuilder` and
  creates or updates them in the database, marked as `managed_by: "code"`.

  ## Examples

      # In application.ex
      Plato.sync_schemas(MyApp.ContentSchemas, otp_app: :my_app)

      # In a migration
      Plato.sync_schemas(MyApp.ContentSchemas, repo: MyApp.Repo)

  ## Options

    * `:repo` - The Ecto repo to use (required if :otp_app not provided)
    * `:otp_app` - The OTP app to read repo config from (required if :repo not provided)
  """
  @spec sync_schemas(module(), opts()) :: :ok | {:error, term()}
  def sync_schemas(schema_module, opts \\ []) do
    repo = get_repo(opts)

    schema_module.__plato_schemas__()
    |> Enum.each(fn schema_def ->
      sync_schema(schema_def, repo)
    end)

    :ok
  end

  # Private helpers

  defp get_repo(opts) do
    cond do
      repo = opts[:repo] ->
        repo

      otp_app = opts[:otp_app] ->
        get_repo_from_app(otp_app)

      otp_app = Application.get_env(:plato, :default_otp_app) ->
        get_repo_from_app(otp_app)

      true ->
        raise ArgumentError, """
        Must provide :repo or :otp_app option, or configure default_otp_app:

            config :plato, default_otp_app: :my_app
        """
    end
  end

  defp get_repo_from_app(otp_app) do
    config = Application.get_env(otp_app, :plato, [])

    case Keyword.fetch(config, :repo) do
      {:ok, repo} ->
        repo

      :error ->
        raise ArgumentError, """
        OTP app #{inspect(otp_app)} has no :plato configuration with :repo.

        Add to your config:

            config #{inspect(otp_app)}, :plato,
              repo: YourApp.Repo
        """
    end
  end

  defp get_schema_by_name(name, repo) do
    case repo.get_by(Schema, name: name) do
      nil -> {:error, :schema_not_found}
      schema -> {:ok, schema}
    end
  end

  defp get_unique_content(schema, repo) do
    case repo.get_by(Content, schema_id: schema.id) do
      nil -> {:error, :content_not_found}
      content -> {:ok, content}
    end
  end

  defp sync_schema(schema_def, repo) do
    # Find or create schema
    schema =
      case repo.get_by(Schema, name: schema_def.name) do
        nil ->
          {:ok, schema} =
            Schema.create(
              %{
                name: schema_def.name,
                unique: schema_def.unique,
                managed_by: "code"
              },
              repo
            )

          schema

        existing ->
          # Update if needed
          {:ok, schema} =
            existing
            |> Schema.changeset(%{
              unique: schema_def.unique,
              managed_by: "code"
            })
            |> repo.update()

          schema
      end

    # Sync fields
    schema = repo.preload(schema, :fields)
    existing_fields_by_name = Map.new(schema.fields, &{&1.name, &1})

    # Create or update fields
    Enum.each(schema_def.fields, fn field_def ->
      field_options = extract_field_options(field_def.opts, field_def.type)

      field_attrs = %{
        schema_id: schema.id,
        name: field_def.name,
        field_type: to_string(field_def.type),
        options: field_options
      }

      # Handle reference fields
      field_attrs =
        if field_def.type == :reference do
          ref_schema_name = Keyword.get(field_def.opts, :to)

          case repo.get_by(Schema, name: ref_schema_name) do
            nil ->
              # Referenced schema doesn't exist yet, will be created on next sync
              field_attrs

            ref_schema ->
              Map.put(field_attrs, :referenced_schema_id, ref_schema.id)
          end
        else
          field_attrs
        end

      case Map.get(existing_fields_by_name, field_def.name) do
        nil ->
          # Create new field
          Plato.Field.create(field_attrs, repo)

        existing_field ->
          # Update existing field if options changed
          if existing_field.options != field_options or
               (field_def.type == :reference and
                  existing_field.referenced_schema_id !=
                    Map.get(field_attrs, :referenced_schema_id)) do
            existing_field
            |> Plato.Field.changeset(field_attrs)
            |> repo.update()
          end
      end
    end)

    :ok
  end

  defp extract_field_options(opts, field_type) do
    # Extract common options first
    base_options = %{}

    base_options =
      if Keyword.has_key?(opts, :as_title) do
        Map.put(base_options, "as_title", Keyword.get(opts, :as_title))
      else
        base_options
      end

    # Add field-type specific options
    type_specific_options =
      case field_type do
        :text ->
          # Extract multiline option for text fields
          if Keyword.has_key?(opts, :multiline) do
            %{"multiline" => Keyword.get(opts, :multiline)}
          else
            %{}
          end

        :reference ->
          # Extract multiple option for reference fields
          if Keyword.has_key?(opts, :multiple) do
            %{"multiple" => Keyword.get(opts, :multiple)}
          else
            %{}
          end

        _ ->
          %{}
      end

    Map.merge(base_options, type_specific_options)
  end
end
