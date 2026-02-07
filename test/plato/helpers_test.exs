defmodule Plato.HelpersTest do
  use Plato.DataCase, async: true
  doctest Plato.Helpers

  import Plato.Helpers

  describe "plato_content/3" do
    test "returns field value for existing content" do
      schema = create_schema(%{name: "homepage", unique: true})
      field = create_field(schema, %{name: "title", field_type: "text"})
      create_content(schema, %{"#{field.id}" => "Welcome"})

      assert plato_content("homepage", :title, repo: Repo) == "Welcome"
    end

    test "returns nil for non-existent schema" do
      assert plato_content("nonexistent", :title, repo: Repo) == nil
    end

    test "returns nil for non-existent field" do
      schema = create_schema(%{name: "page", unique: true})
      field = create_field(schema, %{name: "title", field_type: "text"})
      create_content(schema, %{"#{field.id}" => "Title"})

      assert plato_content("page", :missing_field, repo: Repo) == nil
    end
  end

  describe "plato_render/4" do
    test "renders content with function" do
      schema = create_schema(%{name: "hero", unique: true})
      field = create_field(schema, %{name: "title", field_type: "text"})
      create_content(schema, %{"#{field.id}" => "Hero Title"})

      result =
        plato_render("hero", :title, [repo: Repo], fn value ->
          "Rendered: #{value}"
        end)

      assert result == "Rendered: Hero Title"
    end

    test "returns nil for non-existent content" do
      result =
        plato_render("missing", :field, [repo: Repo], fn value ->
          "Value: #{value}"
        end)

      assert result == nil
    end
  end

  describe "plato_list/3" do
    test "renders list of content" do
      schema = create_schema(%{name: "post"})
      field = create_field(schema, %{name: "title", field_type: "text"})
      create_content(schema, %{"#{field.id}" => "Post 1"})
      create_content(schema, %{"#{field.id}" => "Post 2"})

      results =
        plato_list("post", [repo: Repo], fn post ->
          post.title
        end)

      assert length(results) == 2
      assert "Post 1" in results
      assert "Post 2" in results
    end

    test "returns empty list for non-existent schema" do
      results =
        plato_list("missing", [repo: Repo], fn post ->
          post.title
        end)

      assert results == []
    end
  end
end
