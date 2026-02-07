defmodule Plato.Storage.ConfigTest do
  use ExUnit.Case, async: true

  alias Plato.Storage.Config

  describe "configured?/1" do
    test "returns false when no storage config" do
      # :test_app doesn't have any plato config
      refute Config.configured?(:test_app)
    end

    test "returns false when storage is empty" do
      Application.put_env(:test_app_empty, :plato, storage: [])
      refute Config.configured?(:test_app_empty)
      Application.delete_env(:test_app_empty, :plato)
    end

    test "returns false when only adapter is configured" do
      Application.put_env(:test_app_adapter, :plato,
        storage: [
          adapter: Plato.Storage.S3Adapter
        ]
      )

      refute Config.configured?(:test_app_adapter)
      Application.delete_env(:test_app_adapter, :plato)
    end

    test "returns false when only bucket is configured" do
      Application.put_env(:test_app_bucket, :plato,
        storage: [
          bucket: "my-bucket"
        ]
      )

      refute Config.configured?(:test_app_bucket)
      Application.delete_env(:test_app_bucket, :plato)
    end

    test "returns false when adapter and bucket configured but no credentials" do
      Application.put_env(:test_app_no_creds, :plato,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "my-bucket"
        ]
      )

      refute Config.configured?(:test_app_no_creds)
      Application.delete_env(:test_app_no_creds, :plato)
    end

    test "returns false when access_key_id is nil" do
      Application.put_env(:test_app_nil_access, :plato,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "my-bucket",
          access_key_id: nil,
          secret_access_key: "secret"
        ]
      )

      refute Config.configured?(:test_app_nil_access)
      Application.delete_env(:test_app_nil_access, :plato)
    end

    test "returns false when secret_access_key is nil" do
      Application.put_env(:test_app_nil_secret, :plato,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "my-bucket",
          access_key_id: "key123",
          secret_access_key: nil
        ]
      )

      refute Config.configured?(:test_app_nil_secret)
      Application.delete_env(:test_app_nil_secret, :plato)
    end

    test "returns true when fully configured with credentials" do
      Application.put_env(:test_app_full, :plato,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "my-bucket",
          access_key_id: "AKIAIOSFODNN7EXAMPLE",
          secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        ]
      )

      assert Config.configured?(:test_app_full)
      Application.delete_env(:test_app_full, :plato)
    end

    test "returns true with additional optional config" do
      Application.put_env(:test_app_extra, :plato,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "my-bucket",
          access_key_id: "key123",
          secret_access_key: "secret456",
          region: "us-west-2",
          endpoint: "http://localhost:8333"
        ]
      )

      assert Config.configured?(:test_app_extra)
      Application.delete_env(:test_app_extra, :plato)
    end
  end

  describe "get/1" do
    test "returns empty list when no config" do
      assert Config.get(:nonexistent_app) == []
    end

    test "returns storage config when present" do
      storage_config = [
        adapter: Plato.Storage.S3Adapter,
        bucket: "test-bucket"
      ]

      Application.put_env(:test_app_get, :plato, storage: storage_config)
      assert Config.get(:test_app_get) == storage_config
      Application.delete_env(:test_app_get, :plato)
    end
  end

  describe "adapter/1" do
    test "returns nil when no storage config" do
      assert Config.adapter(:nonexistent_app) == nil
    end

    test "returns adapter module when configured" do
      Application.put_env(:test_app_adapter_get, :plato,
        storage: [
          adapter: Plato.Storage.S3Adapter,
          bucket: "test"
        ]
      )

      assert Config.adapter(:test_app_adapter_get) == Plato.Storage.S3Adapter
      Application.delete_env(:test_app_adapter_get, :plato)
    end
  end
end
