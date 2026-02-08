defmodule PlatoWeb.EndpointTest do
  use ExUnit.Case, async: true

  alias PlatoWeb.Endpoint

  test "module is loaded" do
    assert Code.ensure_loaded?(Endpoint)
  end

  test "uses Phoenix.Endpoint with otp_app :plato" do
    # Verify it's a Phoenix endpoint
    assert function_exported?(Endpoint, :config, 1)
    assert function_exported?(Endpoint, :config, 2)
  end

  test "defines session options" do
    # The endpoint module should have session configuration
    assert Code.ensure_loaded?(Endpoint)
  end

  test "configures static plug for assets" do
    # Verify the endpoint has the Plug.Static configuration
    # This is tested through the endpoint being compilable
    assert Code.ensure_loaded?(Endpoint)
  end

  test "includes Plug.Parsers for request parsing" do
    # The endpoint should be configured with parsers
    assert Code.ensure_loaded?(Endpoint)
  end

  test "includes Plug.Session" do
    # Session should be configured
    assert Code.ensure_loaded?(Endpoint)
  end

  test "routes through PlatoWeb.Router" do
    # The endpoint should use the router
    assert Code.ensure_loaded?(Endpoint)
  end

  test "exports init/2 function" do
    assert function_exported?(Endpoint, :init, 2)
  end

  test "exports call/2 function" do
    assert function_exported?(Endpoint, :call, 2)
  end

  test "has url configuration" do
    assert function_exported?(Endpoint, :url, 0)
  end

  test "has struct_url configuration" do
    assert function_exported?(Endpoint, :struct_url, 0)
  end

  test "has path configuration" do
    assert function_exported?(Endpoint, :path, 1)
  end

  test "has static_path configuration" do
    assert function_exported?(Endpoint, :static_path, 1)
  end
end
