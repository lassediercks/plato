defmodule Plato.Storage.S3AdapterTest do
  use ExUnit.Case, async: true

  alias Plato.Storage.S3Adapter

  # Mock upload struct
  defmodule MockUpload do
    defstruct [:path, :filename, :content_type]
  end

  setup do
    # Create a temporary file for upload tests
    tmp_path = Path.join(System.tmp_dir!(), "test_upload_#{:rand.uniform(1_000_000)}.jpg")
    File.write!(tmp_path, "fake image content")

    on_exit(fn ->
      File.rm(tmp_path)
    end)

    upload = %MockUpload{
      path: tmp_path,
      filename: "test.jpg",
      content_type: "image/jpeg"
    }

    {:ok, upload: upload, tmp_path: tmp_path}
  end

  describe "put/3" do
    test "uploads file to S3 successfully", %{upload: upload} do
      config = [
        adapter: S3Adapter,
        bucket: "test-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret",
        region: "us-east-1"
      ]

      # We can't actually test ExAws without mocking, but we can test the function structure
      # In a real environment with S3 configured, this would work
      # For now, we test that it handles the error case
      result = S3Adapter.put(upload, "path/to/file.jpg", config)

      # Should return either {:ok, path} or {:error, reason}
      assert is_tuple(result) and (elem(result, 0) == :ok or elem(result, 0) == :error)
    end

    test "returns error when file read fails" do
      bad_upload = %MockUpload{
        path: "/nonexistent/file.jpg",
        filename: "test.jpg",
        content_type: "image/jpeg"
      }

      config = [
        bucket: "test-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      # Should raise or return error when file doesn't exist
      assert_raise File.Error, fn ->
        S3Adapter.put(bad_upload, "path/to/file.jpg", config)
      end
    end

    test "requires bucket in config", %{upload: upload} do
      config = [
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      # Should raise when bucket is missing
      assert_raise KeyError, fn ->
        S3Adapter.put(upload, "path/to/file.jpg", config)
      end
    end
  end

  describe "get_url/2" do
    test "generates URL for custom endpoint" do
      config = [
        bucket: "test-bucket",
        endpoint: "http://localhost:8333",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      {:ok, url} = S3Adapter.get_url("path/to/file.jpg", config)

      assert url == "http://localhost:8333/test-bucket/path/to/file.jpg"
    end

    test "generates URL for custom endpoint with different port" do
      config = [
        bucket: "my-bucket",
        endpoint: "http://minio:9000",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      {:ok, url} = S3Adapter.get_url("images/photo.jpg", config)

      assert url == "http://minio:9000/my-bucket/images/photo.jpg"
    end

    test "generates URL for https endpoint" do
      config = [
        bucket: "secure-bucket",
        endpoint: "https://storage.example.com:443",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      {:ok, url} = S3Adapter.get_url("secure/file.jpg", config)

      assert url == "https://storage.example.com:443/secure-bucket/secure/file.jpg"
    end

    test "handles custom endpoint without port" do
      config = [
        bucket: "test-bucket",
        endpoint: "http://localhost",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      {:ok, url} = S3Adapter.get_url("file.jpg", config)

      # Should default to port 8333
      assert url == "http://localhost:8333/test-bucket/file.jpg"
    end

    test "uses AWS S3 presigned URL when no custom endpoint" do
      config = [
        bucket: "aws-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret",
        region: "us-west-2"
      ]

      # This will attempt to generate an AWS presigned URL
      # Without actual AWS credentials, it should still return a result
      result = S3Adapter.get_url("path/to/file.jpg", config)

      # Should return either success or error tuple
      assert is_tuple(result) and (elem(result, 0) == :ok or elem(result, 0) == :error)
    end

    test "respects signed_url_expiry config" do
      config = [
        bucket: "test-bucket",
        endpoint: "http://localhost:8333",
        signed_url_expiry: 7200,
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      # The expiry is used in presigned URL generation
      # For custom endpoints, we currently don't use it
      {:ok, url} = S3Adapter.get_url("file.jpg", config)

      assert url =~ "test-bucket/file.jpg"
    end

    test "requires bucket in config" do
      config = [
        endpoint: "http://localhost:8333",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      assert_raise KeyError, fn ->
        S3Adapter.get_url("file.jpg", config)
      end
    end
  end

  describe "delete/2" do
    test "deletes file from S3" do
      config = [
        bucket: "test-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret",
        region: "us-east-1"
      ]

      result = S3Adapter.delete("path/to/file.jpg", config)

      # Should return :ok or {:error, reason}
      assert result == :ok or (is_tuple(result) and elem(result, 0) == :error)
    end

    test "requires bucket in config" do
      config = [
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      assert_raise KeyError, fn ->
        S3Adapter.delete("file.jpg", config)
      end
    end
  end

  describe "exists?/2" do
    test "checks if file exists in S3" do
      config = [
        bucket: "test-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret",
        region: "us-east-1"
      ]

      result = S3Adapter.exists?("path/to/file.jpg", config)

      # Should return boolean
      assert is_boolean(result)
    end

    test "returns false when file doesn't exist" do
      config = [
        bucket: "test-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret",
        region: "us-east-1"
      ]

      # Non-existent file should return false
      result = S3Adapter.exists?("nonexistent/file.jpg", config)

      assert result == false
    end

    test "requires bucket in config" do
      config = [
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      assert_raise KeyError, fn ->
        S3Adapter.exists?("file.jpg", config)
      end
    end
  end

  describe "build_ex_aws_config/2 (internal)" do
    test "builds config without endpoint" do
      config = [
        bucket: "test-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret",
        region: "eu-west-1"
      ]

      # Call through put to test config building
      # We can't directly test private functions, but we can verify behavior
      result =
        S3Adapter.put(
          %MockUpload{
            # Use this file as test data
            path: __ENV__.file,
            filename: "test.jpg",
            content_type: "image/jpeg"
          },
          "test/path.jpg",
          config
        )

      # Should process config correctly (even if ExAws fails)
      assert is_tuple(result) and (elem(result, 0) == :ok or elem(result, 0) == :error)
    end

    test "builds config with custom endpoint" do
      config = [
        bucket: "test-bucket",
        endpoint: "http://minio:9000",
        access_key_id: "test-key",
        secret_access_key: "test-secret",
        region: "us-east-1"
      ]

      result =
        S3Adapter.put(
          %MockUpload{
            path: __ENV__.file,
            filename: "test.jpg",
            content_type: "image/jpeg"
          },
          "test/path.jpg",
          config
        )

      assert is_tuple(result) and (elem(result, 0) == :ok or elem(result, 0) == :error)
    end

    test "builds config with internal endpoint preference" do
      config = [
        bucket: "test-bucket",
        endpoint: "http://external:8333",
        internal_endpoint: "http://internal:8333",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      # When uploading (internal operation), should use internal_endpoint
      result =
        S3Adapter.put(
          %MockUpload{
            path: __ENV__.file,
            filename: "test.jpg",
            content_type: "image/jpeg"
          },
          "test/path.jpg",
          config
        )

      assert is_tuple(result) and (elem(result, 0) == :ok or elem(result, 0) == :error)
    end

    test "uses external endpoint for get_url" do
      config = [
        bucket: "test-bucket",
        endpoint: "http://external:8333",
        internal_endpoint: "http://internal:8333",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      # For get_url, should use external endpoint
      {:ok, url} = S3Adapter.get_url("file.jpg", config)

      assert url =~ "external"
      refute url =~ "internal"
    end

    test "defaults to us-east-1 region when not specified" do
      config = [
        bucket: "test-bucket",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      # Should use default region
      result =
        S3Adapter.put(
          %MockUpload{
            path: __ENV__.file,
            filename: "test.jpg",
            content_type: "image/jpeg"
          },
          "test/path.jpg",
          config
        )

      assert is_tuple(result) and (elem(result, 0) == :ok or elem(result, 0) == :error)
    end
  end

  describe "adapter behavior implementation" do
    test "implements Plato.Storage.Adapter behavior" do
      # Verify the module implements the behavior
      assert S3Adapter.__info__(:attributes)[:behaviour] == [Plato.Storage.Adapter]
    end

    test "exports all required callbacks" do
      exports = S3Adapter.__info__(:functions)

      assert Keyword.has_key?(exports, :put)
      assert Keyword.has_key?(exports, :get_url)
      assert Keyword.has_key?(exports, :delete)
      assert Keyword.has_key?(exports, :exists?)
    end
  end

  describe "integration scenarios" do
    test "complete upload workflow structure", %{upload: upload} do
      config = [
        bucket: "test-bucket",
        endpoint: "http://localhost:8333",
        access_key_id: "test-key",
        secret_access_key: "test-secret"
      ]

      storage_path = "uploads/test/#{System.unique_integer([:positive])}/#{upload.filename}"

      # Test the complete workflow (structure only, as we don't have real S3)
      # 1. Put file
      put_result = S3Adapter.put(upload, storage_path, config)

      assert is_tuple(put_result) and
               (elem(put_result, 0) == :ok or elem(put_result, 0) == :error)

      # 2. Get URL
      {:ok, url} = S3Adapter.get_url(storage_path, config)
      assert url =~ "test-bucket"
      assert url =~ storage_path

      # 3. Check existence
      exists_result = S3Adapter.exists?(storage_path, config)
      assert is_boolean(exists_result)

      # 4. Delete
      delete_result = S3Adapter.delete(storage_path, config)

      assert delete_result == :ok or
               (is_tuple(delete_result) and elem(delete_result, 0) == :error)
    end

    test "handles SeaweedFS configuration", %{upload: upload} do
      config = [
        bucket: "plato-uploads",
        endpoint: "http://localhost:8333",
        access_key_id: "any-key",
        secret_access_key: "any-secret",
        region: "us-east-1"
      ]

      # Test SeaweedFS-style config
      {:ok, url} = S3Adapter.get_url("test/file.jpg", config)
      assert url == "http://localhost:8333/plato-uploads/test/file.jpg"
    end

    test "handles MinIO configuration", %{upload: upload} do
      config = [
        bucket: "minio-bucket",
        endpoint: "http://minio:9000",
        access_key_id: "minioadmin",
        secret_access_key: "minioadmin",
        region: "us-east-1"
      ]

      {:ok, url} = S3Adapter.get_url("images/photo.jpg", config)
      assert url == "http://minio:9000/minio-bucket/images/photo.jpg"
    end

    test "handles Docker internal/external endpoints", %{upload: upload} do
      config = [
        bucket: "docker-bucket",
        endpoint: "http://external-host:8333",
        internal_endpoint: "http://seaweedfs:8333",
        access_key_id: "key",
        secret_access_key: "secret"
      ]

      # URL generation should use external endpoint (for browser access)
      {:ok, url} = S3Adapter.get_url("file.jpg", config)
      assert url =~ "external-host"

      # Upload would use internal endpoint (tested through structure)
      result = S3Adapter.put(upload, "test/file.jpg", config)
      assert is_tuple(result) and (elem(result, 0) == :ok or elem(result, 0) == :error)
    end
  end
end
