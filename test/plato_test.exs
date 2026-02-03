defmodule PlatoTest do
  use ExUnit.Case
  doctest Plato

  test "greets the world" do
    assert Plato.hello() == :world
  end
end
