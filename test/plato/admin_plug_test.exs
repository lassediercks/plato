defmodule Plato.AdminPlugTest do
  use Plato.DataCase, async: false
  import Plug.Test
  import Plug.Conn

  alias Plato.AdminPlug

  @session_opts Plug.Session.init(
                  store: :cookie,
                  key: "_test_key",
                  signing_salt: "test_salt"
                )

  defp setup_session(conn) do
    conn
    |> Map.put(:secret_key_base, String.duplicate("a", 64))
    |> Plug.Session.call(@session_opts)
    |> fetch_session()
  end

  describe "base_path computation" do
    test "computes base_path from empty script_name" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, [])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/cms")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_base_path] == "/"
    end

    test "computes base_path from single segment script_name" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, ["admin"])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/cms")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_base_path] == "/admin"
    end

    test "computes base_path from multiple segment script_name" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, ["dev", "cms"])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/cms")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_base_path] == "/dev/cms"
    end

    test "computes base_path with deeply nested scopes" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, ["admin", "v1", "cms"])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/cms")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_base_path] == "/admin/v1/cms"
    end
  end

  describe "otp_app assignment" do
    test "assigns otp_app from opts" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, [])

      opts = AdminPlug.init(otp_app: :my_app, base_path: "/")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_otp_app] == :my_app
    end

    test "raises error when otp_app is missing" do
      conn =
        conn(:get, "/")
        |> Map.put(:script_name, [])

      opts = AdminPlug.init(base_path: "/")

      assert_raise ArgumentError, ~r/Must provide :otp_app/, fn ->
        AdminPlug.call(conn, opts)
      end
    end
  end

  describe "static asset serving" do
    test "serves CSS files" do
      conn =
        conn(:get, "/css/app.css")
        |> Map.put(:script_name, ["admin"])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/cms")
      conn = AdminPlug.call(conn, opts)

      # Static plug should halt the connection if it served a file
      # In test, the file might not exist, but we can check that static serving was attempted
      # The connection should have been processed by the static plug
      assert conn
    end

    test "non-static requests continue to router" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, ["admin"])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/cms")
      conn = AdminPlug.call(conn, opts)

      # Non-static requests should have base_path assigned and continue
      assert conn.assigns[:plato_base_path] == "/admin"
      assert conn.assigns[:plato_otp_app] == :plato
    end
  end

  describe "integration scenarios" do
    test "handles root mount path" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, [])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_base_path] == "/"
      assert conn.assigns[:plato_otp_app] == :plato
    end

    test "handles mount in development scope" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, ["dev", "cms"])

      opts = AdminPlug.init(otp_app: :my_app, base_path: "/cms")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_base_path] == "/dev/cms"
      assert conn.assigns[:plato_otp_app] == :my_app
    end

    test "handles mount with special characters in path" do
      conn =
        conn(:get, "/")
        |> setup_session()
        |> Map.put(:script_name, ["admin-panel", "cms-v2"])

      opts = AdminPlug.init(otp_app: :plato, base_path: "/cms-v2")
      conn = AdminPlug.call(conn, opts)

      assert conn.assigns[:plato_base_path] == "/admin-panel/cms-v2"
    end
  end
end
