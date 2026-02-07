defmodule Plato.SchemaBuilderTest do
  use ExUnit.Case, async: true
  doctest Plato.SchemaBuilder

  describe "schema DSL" do
    defmodule TestSchemas do
      use Plato.SchemaBuilder

      schema "test-schema", unique: true do
        field :title, :text
        field :body, :text, multiline: true
      end

      schema "blog-post" do
        field :title, :text
        field :author, :reference, to: "author"
      end
    end

    test "generates schema definitions" do
      schemas = TestSchemas.__plato_schemas__()

      assert length(schemas) == 2

      test_schema = Enum.find(schemas, &(&1.name == "test-schema"))
      assert test_schema.unique == true
      assert length(test_schema.fields) == 2

      blog_schema = Enum.find(schemas, &(&1.name == "blog-post"))
      assert blog_schema.unique == false
      assert length(blog_schema.fields) == 2
    end

    test "field definitions include options" do
      schemas = TestSchemas.__plato_schemas__()

      test_schema = Enum.find(schemas, &(&1.name == "test-schema"))
      body_field = Enum.find(test_schema.fields, &(&1.name == "body"))

      assert body_field.type == :text
      assert Keyword.get(body_field.opts, :multiline) == true
    end

    test "reference fields include target schema" do
      schemas = TestSchemas.__plato_schemas__()

      blog_schema = Enum.find(schemas, &(&1.name == "blog-post"))
      author_field = Enum.find(blog_schema.fields, &(&1.name == "author"))

      assert author_field.type == :reference
      assert Keyword.get(author_field.opts, :to) == "author"
    end
  end

  describe "field options" do
    defmodule FieldOptionsSchemas do
      use Plato.SchemaBuilder

      schema "article" do
        field :title, :text, as_title: true
        field :excerpt, :text, multiline: true
        field :cover, :image
      end
    end

    test "supports as_title option" do
      schemas = FieldOptionsSchemas.__plato_schemas__()
      article = Enum.find(schemas, &(&1.name == "article"))
      title_field = Enum.find(article.fields, &(&1.name == "title"))

      assert Keyword.get(title_field.opts, :as_title) == true
    end

    test "supports multiline option" do
      schemas = FieldOptionsSchemas.__plato_schemas__()
      article = Enum.find(schemas, &(&1.name == "article"))
      excerpt_field = Enum.find(article.fields, &(&1.name == "excerpt"))

      assert Keyword.get(excerpt_field.opts, :multiline) == true
    end

    test "supports image field type" do
      schemas = FieldOptionsSchemas.__plato_schemas__()
      article = Enum.find(schemas, &(&1.name == "article"))
      cover_field = Enum.find(article.fields, &(&1.name == "cover"))

      assert cover_field.type == :image
    end
  end
end
