defmodule Plato.SchemaBuilderTest do
  use ExUnit.Case, async: true

  describe "schema/2 macro" do
    test "defines a schema without options" do
      defmodule BasicSchema do
        use Plato.SchemaBuilder

        schema "article" do
          field :title, :text
        end
      end

      schemas = BasicSchema.__plato_schemas__()
      assert length(schemas) == 1

      schema = hd(schemas)
      assert schema.name == "article"
      assert schema.unique == false
      assert length(schema.fields) == 1
    end

    test "defines a unique schema" do
      defmodule UniqueSchema do
        use Plato.SchemaBuilder

        schema "homepage", unique: true do
          field :title, :text
        end
      end

      schemas = UniqueSchema.__plato_schemas__()
      schema = hd(schemas)
      assert schema.unique == true
    end

    test "defines multiple schemas" do
      defmodule MultipleSchemas do
        use Plato.SchemaBuilder

        schema "blog_post" do
          field :title, :text
        end

        schema "author" do
          field :name, :text
        end

        schema "category" do
          field :label, :text
        end
      end

      schemas = MultipleSchemas.__plato_schemas__()
      assert length(schemas) == 3

      names = Enum.map(schemas, & &1.name)
      assert "blog_post" in names
      assert "author" in names
      assert "category" in names
    end
  end

  describe "field/3 macro" do
    test "defines text fields" do
      defmodule TextFields do
        use Plato.SchemaBuilder

        schema "page" do
          field :title, :text
          field :body, :text
          field :summary, :text
        end
      end

      schema = hd(TextFields.__plato_schemas__())
      assert length(schema.fields) == 3

      field_names = Enum.map(schema.fields, & &1.name)
      assert "title" in field_names
      assert "body" in field_names
      assert "summary" in field_names

      Enum.each(schema.fields, fn field ->
        assert field.type == :text
      end)
    end

    test "defines reference fields with 'to' option" do
      defmodule ReferenceFields do
        use Plato.SchemaBuilder

        schema "blog_post" do
          field :title, :text
          field :author, :reference, to: "author"
          field :category, :reference, to: "category"
        end
      end

      schema = hd(ReferenceFields.__plato_schemas__())
      fields = schema.fields

      author_field = Enum.find(fields, &(&1.name == "author"))
      assert author_field.type == :reference
      assert author_field.opts[:to] == "author"

      category_field = Enum.find(fields, &(&1.name == "category"))
      assert category_field.type == :reference
      assert category_field.opts[:to] == "category"
    end

    test "converts field names to strings" do
      defmodule FieldNameConversion do
        use Plato.SchemaBuilder

        schema "test" do
          field :my_field, :text
          field :another_field, :text
        end
      end

      schema = hd(FieldNameConversion.__plato_schemas__())

      Enum.each(schema.fields, fn field ->
        assert is_binary(field.name)
      end)
    end

    test "preserves field order" do
      defmodule FieldOrder do
        use Plato.SchemaBuilder

        schema "ordered" do
          field :first, :text
          field :second, :text
          field :third, :text
        end
      end

      schema = hd(FieldOrder.__plato_schemas__())
      field_names = Enum.map(schema.fields, & &1.name)
      assert field_names == ["first", "second", "third"]
    end
  end

  describe "complex schema definitions" do
    test "supports nested references" do
      defmodule NestedReferences do
        use Plato.SchemaBuilder

        schema "blog_post" do
          field :title, :text
          field :body, :text
          field :author, :reference, to: "author"
          field :category, :reference, to: "category"
        end

        schema "author" do
          field :name, :text
          field :bio, :text
          field :avatar, :reference, to: "image"
        end

        schema "category" do
          field :name, :text
        end

        schema "image" do
          field :url, :text
          field :alt_text, :text
        end
      end

      schemas = NestedReferences.__plato_schemas__()
      assert length(schemas) == 4

      blog_post = Enum.find(schemas, &(&1.name == "blog_post"))
      assert length(blog_post.fields) == 4

      reference_fields =
        Enum.filter(blog_post.fields, &(&1.type == :reference))

      assert length(reference_fields) == 2
    end

    test "supports schemas with only reference fields" do
      defmodule OnlyReferences do
        use Plato.SchemaBuilder

        schema "post_meta" do
          field :author, :reference, to: "author"
          field :category, :reference, to: "category"
          field :featured_image, :reference, to: "image"
        end
      end

      schema = hd(OnlyReferences.__plato_schemas__())
      assert length(schema.fields) == 3

      Enum.each(schema.fields, fn field ->
        assert field.type == :reference
      end)
    end

    test "supports empty schemas" do
      defmodule EmptySchema do
        use Plato.SchemaBuilder

        schema "empty" do
        end
      end

      schema = hd(EmptySchema.__plato_schemas__())
      assert schema.name == "empty"
      assert schema.fields == []
    end
  end

  describe "schema builder options" do
    test "unique defaults to false" do
      defmodule DefaultUnique do
        use Plato.SchemaBuilder

        schema "test" do
          field :name, :text
        end
      end

      schema = hd(DefaultUnique.__plato_schemas__())
      assert schema.unique == false
    end

    test "supports unique: true" do
      defmodule UniqueTrue do
        use Plato.SchemaBuilder

        schema "settings", unique: true do
          field :key, :text
        end
      end

      schema = hd(UniqueTrue.__plato_schemas__())
      assert schema.unique == true
    end

    test "supports unique: false explicitly" do
      defmodule UniqueFalse do
        use Plato.SchemaBuilder

        schema "posts", unique: false do
          field :title, :text
        end
      end

      schema = hd(UniqueFalse.__plato_schemas__())
      assert schema.unique == false
    end
  end

  describe "field options" do
    test "captures field options" do
      defmodule FieldOptions do
        use Plato.SchemaBuilder

        schema "test" do
          field :author, :reference, to: "author"
        end
      end

      schema = hd(FieldOptions.__plato_schemas__())
      field = hd(schema.fields)
      assert field.opts == [to: "author"]
    end

    test "handles empty field options" do
      defmodule NoFieldOptions do
        use Plato.SchemaBuilder

        schema "test" do
          field :title, :text
        end
      end

      schema = hd(NoFieldOptions.__plato_schemas__())
      field = hd(schema.fields)
      assert field.opts == []
    end

    test "handles multiple options" do
      defmodule MultipleFieldOptions do
        use Plato.SchemaBuilder

        schema "test" do
          field :ref, :reference, to: "other", optional: true
        end
      end

      schema = hd(MultipleFieldOptions.__plato_schemas__())
      field = hd(schema.fields)
      assert Keyword.get(field.opts, :to) == "other"
      assert Keyword.get(field.opts, :optional) == true
    end
  end

  describe "__plato_schemas__/0 function" do
    test "returns all defined schemas" do
      defmodule AllSchemas do
        use Plato.SchemaBuilder

        schema "first" do
          field :a, :text
        end

        schema "second", unique: true do
          field :b, :text
        end
      end

      schemas = AllSchemas.__plato_schemas__()
      assert is_list(schemas)
      assert length(schemas) == 2
    end

    test "returns empty list when no schemas defined" do
      defmodule NoSchemas do
        use Plato.SchemaBuilder
      end

      assert NoSchemas.__plato_schemas__() == []
    end
  end

  describe "real-world schema examples" do
    test "blog schema definition" do
      defmodule BlogSchemas do
        use Plato.SchemaBuilder

        schema "blog_post" do
          field :title, :text
          field :slug, :text
          field :body, :text
          field :excerpt, :text
          field :author, :reference, to: "author"
          field :featured_image, :reference, to: "image"
        end

        schema "author" do
          field :name, :text
          field :email, :text
          field :bio, :text
          field :avatar, :reference, to: "image"
        end

        schema "image" do
          field :url, :text
          field :alt_text, :text
          field :caption, :text
        end
      end

      schemas = BlogSchemas.__plato_schemas__()
      assert length(schemas) == 3

      blog_post = Enum.find(schemas, &(&1.name == "blog_post"))
      assert length(blog_post.fields) == 6

      text_fields =
        Enum.filter(blog_post.fields, &(&1.type == :text))

      assert length(text_fields) == 4
    end

    test "e-commerce schema definition" do
      defmodule EcommerceSchemas do
        use Plato.SchemaBuilder

        schema "product" do
          field :name, :text
          field :description, :text
          field :price, :text
          field :category, :reference, to: "category"
          field :image, :reference, to: "image"
        end

        schema "category" do
          field :name, :text
        end

        schema "image" do
          field :url, :text
        end
      end

      schemas = EcommerceSchemas.__plato_schemas__()
      assert length(schemas) == 3

      product = Enum.find(schemas, &(&1.name == "product"))
      assert product != nil
      assert length(product.fields) == 5
    end

    test "settings schema with unique constraint" do
      defmodule SettingsSchemas do
        use Plato.SchemaBuilder

        schema "site_settings", unique: true do
          field :site_name, :text
          field :site_description, :text
          field :logo, :reference, to: "image"
        end

        schema "image" do
          field :url, :text
        end
      end

      schemas = SettingsSchemas.__plato_schemas__()
      settings = Enum.find(schemas, &(&1.name == "site_settings"))

      assert settings.unique == true
      assert length(settings.fields) == 3
    end
  end
end
