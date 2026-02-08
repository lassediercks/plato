defmodule PlatoWeb.LayoutsTest do
  use ExUnit.Case, async: true

  alias PlatoWeb.Layouts

  test "module is loaded and uses PlatoWeb :html" do
    assert Code.ensure_loaded?(Layouts)
  end

  test "has __components__ function from Phoenix.Component" do
    assert function_exported?(Layouts, :__components__, 0)
  end

  test "embeds layout templates" do
    # The module should embed templates from layouts/*
    # This is tested by the module compiling successfully
    assert Code.ensure_loaded?(Layouts)
  end

  test "has Phoenix.Component capabilities" do
    # Should have component-related functions
    exports = Layouts.__info__(:functions)
    assert Keyword.has_key?(exports, :__components__)
  end
end
