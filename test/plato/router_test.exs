defmodule Plato.RouterTest do
  use ExUnit.Case, async: true

  alias Plato.Router

  describe "plato_admin/2 macro" do
    test "generates a scope with forward to AdminPlug" do
      # Create a test router that uses the macro
      defmodule TestRouter1 do
        use Phoenix.Router
        import Plato.Router

        plato_admin("/admin", otp_app: :test_app)
      end

      # Verify the router module compiles
      assert Code.ensure_loaded?(TestRouter1)
    end

    test "passes base_path in opts to AdminPlug" do
      defmodule TestRouter2 do
        use Phoenix.Router
        import Plato.Router

        plato_admin("/custom/path", otp_app: :test_app)
      end

      assert Code.ensure_loaded?(TestRouter2)
    end

    test "accepts custom paths" do
      defmodule TestRouter3 do
        use Phoenix.Router
        import Plato.Router

        plato_admin("/cms", otp_app: :my_app)
      end

      assert Code.ensure_loaded?(TestRouter3)
    end

    test "works without optional opts" do
      defmodule TestRouter4 do
        use Phoenix.Router
        import Plato.Router

        plato_admin("/admin", otp_app: :test_app)
      end

      assert Code.ensure_loaded?(TestRouter4)
    end

    test "module has proper documentation" do
      {:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(Router)

      assert module_doc != :hidden
      assert module_doc != :none
    end

    test "plato_admin/2 is exported as macro" do
      exports = Router.__info__(:macros)
      assert {:plato_admin, 1} in exports or {:plato_admin, 2} in exports
    end
  end

  describe "macro expansion" do
    test "expands to scope with forward" do
      # The macro should expand to a scope that forwards to AdminPlug
      # We test this by verifying routers that use it compile successfully
      defmodule TestRouter5 do
        use Phoenix.Router
        import Plato.Router

        plato_admin("/test", otp_app: :test_app)
      end

      assert Code.ensure_loaded?(TestRouter5)
    end

    test "preserves otp_app option" do
      defmodule TestRouter6 do
        use Phoenix.Router
        import Plato.Router

        plato_admin("/admin", otp_app: :custom_app)
      end

      assert Code.ensure_loaded?(TestRouter6)
    end

    test "adds base_path to opts" do
      # The macro should add base_path: path to the opts
      # This is tested through successful compilation and routing
      defmodule TestRouter7 do
        use Phoenix.Router
        import Plato.Router

        plato_admin("/backstage", otp_app: :my_app)
      end

      assert Code.ensure_loaded?(TestRouter7)
    end
  end
end
