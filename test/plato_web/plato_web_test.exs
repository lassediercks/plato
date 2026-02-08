defmodule PlatoWebTest do
  use ExUnit.Case, async: true

  describe "html/0" do
    test "returns quoted expression for HTML helpers" do
      result = PlatoWeb.html()

      assert match?({:__block__, _, _}, result)
    end

    test "includes Phoenix.Component" do
      # Create a test module using the html macro
      defmodule TestHTMLModule do
        use PlatoWeb, :html
      end

      # Verify it has Phoenix.Component functions
      exports = TestHTMLModule.__info__(:functions)
      assert Keyword.has_key?(exports, :__components__)
    end
  end

  describe "verified_routes/0" do
    test "returns quoted expression for verified routes" do
      result = PlatoWeb.verified_routes()

      # Should return a quoted expression (either a block or single expression)
      assert is_tuple(result)
      assert elem(result, 0) in [:__block__, :use, :quote, :import]
    end
  end

  describe "__using__/1" do
    test "calls html/0 when using :html" do
      defmodule TestUsingHTML do
        use PlatoWeb, :html
      end

      # Verify the module was set up with html functionality
      assert Code.ensure_loaded?(TestUsingHTML)
      exports = TestUsingHTML.__info__(:functions)
      assert length(exports) > 0
    end

    test "raises error for unknown usage type" do
      assert_raise UndefinedFunctionError, fn ->
        defmodule TestUsingInvalid do
          use PlatoWeb, :nonexistent
        end
      end
    end
  end
end
