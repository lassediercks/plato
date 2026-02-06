defmodule Plato.Storage.S3Adapter do
  @moduledoc """
  S3 storage adapter using ExAws.

  Supports AWS S3 and S3-compatible services like SeaweedFS.
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

  defp ex_aws_request(operation, config, endpoint_type \\ :internal) do
    config_opts = build_ex_aws_config(config, endpoint_type)
    ExAws.request(operation, config_opts)
  end

  defp build_ex_aws_config(config, endpoint_type \\ :external) do
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
