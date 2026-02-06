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

  Returns true if both adapter and bucket are configured.
  """
  def configured?(otp_app) do
    config = get(otp_app)
    Keyword.has_key?(config, :adapter) && Keyword.has_key?(config, :bucket)
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
