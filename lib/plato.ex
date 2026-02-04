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
        content = repo.preload(content, [schema: :fields])
        field_values = ContentResolver.prepare_field_values(attrs, content.schema)

        case content
             |> Content.changeset(%{field_values: field_values})
             |> repo.update() do
          {:ok, updated_content} ->
            resolved = ContentResolver.resolve_fields(updated_content, repo)
            {:ok, resolved}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
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
    otp_app
    |> Application.get_env(:plato, [])
    |> Keyword.fetch!(:repo)
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
end
