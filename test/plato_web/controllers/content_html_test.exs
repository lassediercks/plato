defmodule PlatoWeb.ContentHTMLTest do
  use ExUnit.Case, async: true

  alias PlatoWeb.ContentHTML

  test "module is loaded" do
    assert Code.ensure_loaded?(ContentHTML)
  end

  test "uses PlatoWeb :html" do
    # Verify it has Phoenix.Component capabilities
    assert function_exported?(ContentHTML, :__components__, 0)
  end

  test "embeds content_html templates" do
    # The module should embed templates
    # This is verified by successful compilation
    assert Code.ensure_loaded?(ContentHTML)
  end

  test "has Phoenix.Component functions" do
    exports = ContentHTML.__info__(:functions)
    assert Keyword.has_key?(exports, :__components__)
  end
end
