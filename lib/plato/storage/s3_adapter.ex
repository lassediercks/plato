defmodule Plato.Storage.S3Adapter do
  @moduledoc """
  S3 storage adapter for Plato image fields using ExAws.

  Supports AWS S3 and S3-compatible services like SeaweedFS, MinIO, and others.

  ## Dependencies

  Add these to your `mix.exs` to use image fields:

      def deps do
        [
          {:plato, "~> 0.0.19"},

          # Required for image fields
          {:ex_aws, "~> 2.5"},
          {:ex_aws_s3, "~> 2.5"},
          {:hackney, "~> 1.20"}
        ]
      end

  ## Configuration

  Configure storage in `config/config.exs` or `config/runtime.exs`:

      # AWS S3 (production)
      config :my_app, :plato,
        repo: MyApp.Repo,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "my-app-uploads",
          region: "us-east-1",
          access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
          secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
          signed_url_expiry: 3600  # URL expiry in seconds
        ]

      # SeaweedFS (local development)
      config :my_app, :plato,
        repo: MyApp.Repo,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "plato-uploads",
          endpoint: "http://localhost:8333",
          access_key_id: "any-key",
          secret_access_key: "any-secret",
          region: "us-east-1"
        ]

  ## Configuration Options

  **Required:**
  - `:adapter` - Must be `Plato.Storage.S3Adapter`
  - `:bucket` - S3 bucket name
  - `:access_key_id` - AWS/S3 access key
  - `:secret_access_key` - AWS/S3 secret key

  **Optional:**
  - `:region` - AWS region (default: "us-east-1")
  - `:endpoint` - Custom endpoint for S3-compatible services
  - `:internal_endpoint` - Endpoint for server-side operations (useful in Docker)
  - `:signed_url_expiry` - URL expiration in seconds (default: 3600)

  ## Local Development with SeaweedFS

  SeaweedFS provides an S3-compatible API perfect for local development.

  Add to `docker-compose.yml`:

      services:
        seaweedfs:
          image: chrislusf/seaweedfs:latest
          command: "server -s3 -dir=/data"
          ports:
            - "8333:8333"  # S3 API
            - "9333:9333"  # Master
            - "8080:8080"  # Volume
          volumes:
            - seaweedfs_data:/data

      volumes:
        seaweedfs_data:

  Create bucket:

      curl -X POST 'http://localhost:8080/buckets' \\
        -H 'Content-Type: application/json' \\
        -d '{"name":"plato-uploads"}'

  See the [Plato Starter Repository](https://github.com/lassediercks/plato) for a
  complete working example with SeaweedFS.

  ## Upload Size Limits

  Configure Phoenix to accept larger uploads in your endpoint:

      # lib/my_app_web/endpoint.ex
      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Phoenix.json_library(),
        length: 100_000_000  # 100MB limit (default is 8MB)

  ## Image Field Usage

  Once configured, image fields can be added to schemas:

      schema "blog-post" do
        field :title, :text
        field :cover_image, :image
        field :body, :text, multiline: true
      end

  Uploaded images are stored with metadata:

      %{
        "url" => "http://localhost:8333/bucket/path/to/image.jpg",
        "storage_path" => "app/schema/field/timestamp_hash_filename.jpg",
        "filename" => "original-filename.jpg",
        "content_type" => "image/jpeg",
        "size_bytes" => 245678
      }

  Access in templates:

      <%= if post.cover_image do %>
        <img src="<%= post.cover_image["url"] %>" alt="<%= post.title %>">
      <% end %>
  """

  @behaviour Plato.Storage.Adapter

  @impl true
  def put(upload, storage_path, config) do
    bucket = Keyword.fetch!(config, :bucket)

    file_binary = File.read!(upload.path)

    bucket
    |> ExAws.S3.put_object(storage_path, file_binary,
      content_type: upload.content_type,
      acl: :private
    )
    |> ex_aws_request(config, :internal)
    |> case do
      {:ok, _} -> {:ok, storage_path}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def get_url(storage_path, config) do
    bucket = Keyword.fetch!(config, :bucket)
    expiry = Keyword.get(config, :signed_url_expiry, 3600)

    # Use regular endpoint for browser-accessible URLs
    endpoint = Keyword.get(config, :endpoint)

    if endpoint do
      # For custom endpoints, build URL manually
      # SeaweedFS and other S3-compatible services work fine with simple signed URLs
      uri = URI.parse(endpoint)
      scheme = uri.scheme || "http"
      host = uri.host || "localhost"
      port = uri.port || 8333

      # Build the URL manually
      url = "#{scheme}://#{host}:#{port}/#{bucket}/#{storage_path}"

      # For now, generate unsigned URL - SeaweedFS doesn't require auth by default
      {:ok, url}
    else
      # Use AWS S3 with proper presigned URLs
      config_opts = build_ex_aws_config(config, :external)
      ex_aws_config = ExAws.Config.new(:s3, config_opts)

      case ExAws.S3.presigned_url(ex_aws_config, :get, bucket, storage_path,
             expires_in: expiry
           ) do
        {:ok, signed_url} -> {:ok, signed_url}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @impl true
  def delete(storage_path, config) do
    bucket = Keyword.fetch!(config, :bucket)

    bucket
    |> ExAws.S3.delete_object(storage_path)
    |> ex_aws_request(config, :internal)
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def exists?(storage_path, config) do
    bucket = Keyword.fetch!(config, :bucket)

    bucket
    |> ExAws.S3.head_object(storage_path)
    |> ex_aws_request(config, :internal)
    |> case do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  # Private helpers

  defp ex_aws_request(operation, config, endpoint_type) do
    config_opts = build_ex_aws_config(config, endpoint_type)
    ExAws.request(operation, config_opts)
  end

  defp build_ex_aws_config(config, endpoint_type) do
    base_config = [
      access_key_id: Keyword.get(config, :access_key_id),
      secret_access_key: Keyword.get(config, :secret_access_key),
      region: Keyword.get(config, :region, "us-east-1")
    ]

    # Choose endpoint based on type (internal for uploads, external for URLs)
    endpoint =
      case endpoint_type do
        :internal -> Keyword.get(config, :internal_endpoint) || Keyword.get(config, :endpoint)
        :external -> Keyword.get(config, :endpoint)
      end

    # Add endpoint for S3-compatible services (SeaweedFS, MinIO, etc.)
    case endpoint do
      nil ->
        base_config

      endpoint_url ->
        # Parse the endpoint URL to extract host, port, and scheme
        uri = URI.parse(endpoint_url)

        base_config
        |> Keyword.put(:scheme, uri.scheme || "http")
        |> Keyword.put(:host, uri.host || "localhost")
        |> Keyword.put(:port, uri.port || 8333)
    end
  end
end
