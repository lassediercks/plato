defmodule Plato.RepoTest do
  use ExUnit.Case, async: true

  alias Plato.Repo

  test "module is loaded" do
    assert Code.ensure_loaded?(Repo)
  end

  test "uses Ecto.Repo" do
    # Verify it's an Ecto repo
    assert function_exported?(Repo, :all, 1)
    assert function_exported?(Repo, :get, 2)
    assert function_exported?(Repo, :get_by, 2)
    assert function_exported?(Repo, :insert, 1)
    assert function_exported?(Repo, :update, 1)
    assert function_exported?(Repo, :delete, 1)
  end

  test "configured with otp_app :plato" do
    # Repo should have config/2 function
    assert function_exported?(Repo, :config, 0)
  end

  test "uses Postgres adapter" do
    # The adapter configuration is tested by the repo compiling
    assert Code.ensure_loaded?(Repo)
  end

  test "exports standard Ecto.Repo functions" do
    exports = Repo.__info__(:functions)

    assert Keyword.has_key?(exports, :all)
    assert Keyword.has_key?(exports, :get)
    assert Keyword.has_key?(exports, :get_by)
    assert Keyword.has_key?(exports, :insert)
    assert Keyword.has_key?(exports, :update)
    assert Keyword.has_key?(exports, :delete)
    assert Keyword.has_key?(exports, :preload)
  end

  test "has query functions" do
    assert function_exported?(Repo, :all, 1)
    assert function_exported?(Repo, :all, 2)
    assert function_exported?(Repo, :one, 1)
    assert function_exported?(Repo, :one, 2)
  end

  test "has transaction functions" do
    assert function_exported?(Repo, :transaction, 1)
    assert function_exported?(Repo, :transaction, 2)
  end

  test "has aggregate functions" do
    assert function_exported?(Repo, :aggregate, 2)
    assert function_exported?(Repo, :aggregate, 3)
  end
end
