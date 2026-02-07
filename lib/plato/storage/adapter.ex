defmodule Plato.Storage.Adapter do
  @moduledoc """
  Behaviour for storage adapters in Plato CMS.

  Allows pluggable storage backends (S3, local filesystem, etc.)
  """

  @type upload :: %{
          filename: String.t(),
          path: String.t(),
          content_type: String.t()
        }

  @type storage_path :: String.t()
  @type url :: String.t()
  @type config :: keyword()

  @doc "Upload a file to storage"
  @callback put(upload, storage_path, config) :: {:ok, storage_path} | {:error, term()}

  @doc "Get a URL for accessing the stored file"
  @callback get_url(storage_path, config) :: {:ok, url} | {:error, term()}

  @doc "Delete a file from storage"
  @callback delete(storage_path, config) :: :ok | {:error, term()}

  @doc "Check if a file exists in storage"
  @callback exists?(storage_path, config) :: boolean()
end
