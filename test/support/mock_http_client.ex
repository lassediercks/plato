defmodule Plato.MockHTTPClient do
  @moduledoc false
  # Mock HTTP client for ExAws in tests to avoid actual network calls

  @behaviour ExAws.Request.HttpClient

  @impl true
  def request(method, _url, _body, _headers, _opts) do
    # Return appropriate mock responses based on the operation
    cond do
      # HEAD requests for exists? check
      method == :head ->
        {:ok, %{status_code: 404, headers: [], body: ""}}

      # PUT requests for uploads
      method == :put ->
        {:ok, %{status_code: 200, headers: [], body: ""}}

      # DELETE requests
      method == :delete ->
        {:ok, %{status_code: 204, headers: [], body: ""}}

      # GET requests
      method == :get ->
        {:ok, %{status_code: 200, headers: [], body: ""}}

      true ->
        {:ok, %{status_code: 200, headers: [], body: ""}}
    end
  end
end
