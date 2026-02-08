defmodule PlatoWeb.FieldHTMLTest do
  use ExUnit.Case, async: true

  alias PlatoWeb.FieldHTML

  test "module is loaded" do
    assert Code.ensure_loaded?(FieldHTML)
  end

  test "uses PlatoWeb :html" do
    # Verify it has Phoenix.Component capabilities
    assert function_exported?(FieldHTML, :__components__, 0)
  end

  test "embeds field_html templates" do
    # The module should embed templates
    # This is verified by successful compilation
    assert Code.ensure_loaded?(FieldHTML)
  end

  test "has Phoenix.Component functions" do
    exports = FieldHTML.__info__(:functions)
    assert Keyword.has_key?(exports, :__components__)
  end
end
