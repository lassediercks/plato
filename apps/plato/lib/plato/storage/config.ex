defmodule Plato.Storage.Config do
  @moduledoc """
  Helper functions for retrieving storage configuration.
  """

  @doc """
  Get storage configuration for an otp_app.

  Returns the storage keyword list from the app's Plato configuration.
  """
  def get(otp_app) do
    otp_app
    |> Application.get_env(:plato, [])
    |> Keyword.get(:storage, [])
  end

  @doc """
  Check if storage is properly configured for an otp_app.

  Returns true if adapter, bucket, and credentials are configured.
  For S3, requires access_key_id and secret_access_key.
  """
  def configured?(otp_app) do
    config = get(otp_app)

    has_adapter? = Keyword.has_key?(config, :adapter)
    has_bucket? = Keyword.has_key?(config, :bucket)
    has_credentials? = has_required_credentials?(config)

    has_adapter? && has_bucket? && has_credentials?
  end

  # Check if required credentials are present
  # Both access_key_id and secret_access_key must be non-nil
  defp has_required_credentials?(config) do
    access_key = Keyword.get(config, :access_key_id)
    secret_key = Keyword.get(config, :secret_access_key)

    not is_nil(access_key) && not is_nil(secret_key)
  end

  @doc """
  Get the storage adapter module for an otp_app.

  Returns the adapter module or nil if not configured.
  """
  def adapter(otp_app) do
    otp_app
    |> get()
    |> Keyword.get(:adapter)
  end
end
