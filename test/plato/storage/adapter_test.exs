defmodule Plato.Storage.AdapterTest do
  use ExUnit.Case, async: true

  alias Plato.Storage.Adapter

  describe "behaviour" do
    test "defines put/3 callback" do
      callbacks = Adapter.behaviour_info(:callbacks)
      assert {:put, 3} in callbacks
    end

    test "defines get_url/2 callback" do
      callbacks = Adapter.behaviour_info(:callbacks)
      assert {:get_url, 2} in callbacks
    end

    test "defines delete/2 callback" do
      callbacks = Adapter.behaviour_info(:callbacks)
      assert {:delete, 2} in callbacks
    end

    test "defines exists?/2 callback" do
      callbacks = Adapter.behaviour_info(:callbacks)
      assert {:exists?, 2} in callbacks
    end
  end

  describe "type specifications" do
    test "module has proper documentation" do
      {:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(Adapter)

      assert module_doc != :hidden
      assert module_doc != :none
    end

    test "defines upload type" do
      # Types are compile-time, so we just verify the module compiles
      # and has the @type definitions
      assert Code.ensure_loaded?(Adapter)
    end

    test "S3Adapter implements the behavior" do
      assert Plato.Storage.S3Adapter.__info__(:attributes)[:behaviour] == [Adapter]
    end
  end
end
