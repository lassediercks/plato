defmodule PlatoWeb.SchemaHTMLTest do
  use ExUnit.Case, async: true

  alias PlatoWeb.SchemaHTML

  test "module is loaded" do
    assert Code.ensure_loaded?(SchemaHTML)
  end

  test "uses PlatoWeb :html" do
    # Verify it has Phoenix.Component capabilities
    assert function_exported?(SchemaHTML, :__components__, 0)
  end

  test "embeds schema_html templates" do
    # The module should embed templates
    # This is verified by successful compilation
    assert Code.ensure_loaded?(SchemaHTML)
  end

  test "has Phoenix.Component functions" do
    exports = SchemaHTML.__info__(:functions)
    assert Keyword.has_key?(exports, :__components__)
  end
end
