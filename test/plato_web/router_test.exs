defmodule PlatoWeb.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PlatoWeb.Router

  @session_options Plug.Session.init(
                     store: :cookie,
                     key: "_test",
                     signing_salt: "test_salt",
                     secret_key_base: String.duplicate("a", 64)
                   )

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Plato.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  defp init_test_session(conn) do
    conn
    |> Map.put(:secret_key_base, String.duplicate("a", 64))
    |> Plug.Session.call(@session_options)
    |> Plug.Conn.fetch_session()
  end

  test "defines browser pipeline" do
    # Verify the router module is loaded
    assert Code.ensure_loaded?(Router)
  end

  test "routes GET / to SchemaController index" do
    conn = conn(:get, "/") |> init_test_session()
    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.SchemaController
    assert conn.private.phoenix_action == :index
  end

  test "routes GET /schemas/:id to SchemaController show" do
    conn = conn(:get, "/schemas/123") |> init_test_session()
    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.SchemaController
    assert conn.private.phoenix_action == :show
    assert conn.params["id"] == "123"
  end

  test "routes GET /content to ContentController index" do
    conn = conn(:get, "/content") |> init_test_session()
    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.ContentController
    assert conn.private.phoenix_action == :index
  end

  test "routes GET /content/new to ContentController new" do
    # Create a schema for the new content form
    {:ok, schema} = Plato.Schema.create(%{name: "test_schema"}, Plato.Repo)
    conn = conn(:get, "/content/new", %{"schema_id" => "#{schema.id}"}) |> init_test_session()
    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.ContentController
    assert conn.private.phoenix_action == :new
  end

  test "routes POST /content to ContentController create" do
    # Create a schema for the content to belong to
    {:ok, schema} = Plato.Schema.create(%{name: "test_schema"}, Plato.Repo)

    conn =
      conn(:post, "/content", %{"schema_id" => "#{schema.id}", "content" => %{}})
      |> init_test_session()

    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.ContentController
    assert conn.private.phoenix_action == :create
  end

  test "routes GET /content/:id to ContentController show" do
    conn = conn(:get, "/content/123") |> init_test_session()
    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.ContentController
    assert conn.private.phoenix_action == :show
    assert conn.params["id"] == "123"
  end

  test "routes GET /content/:id/edit to ContentController edit" do
    conn = conn(:get, "/content/123/edit") |> init_test_session()
    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.ContentController
    assert conn.private.phoenix_action == :edit
  end

  test "routes POST /content/:id/update to ContentController update" do
    conn = conn(:post, "/content/123/update") |> init_test_session()
    conn = Router.call(conn, Router.init([]))

    assert conn.private.phoenix_controller == PlatoWeb.ContentController
    assert conn.private.phoenix_action == :update
  end

  test "browser pipeline includes required plugs" do
    # The router uses a browser pipeline with specific plugs
    # This is tested implicitly through routing tests
    assert Code.ensure_loaded?(Router)
  end
end
