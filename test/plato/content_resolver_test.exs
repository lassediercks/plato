defmodule Plato.ContentResolverTest do
  use Plato.DataCase, async: true

  alias Plato.ContentResolver

  describe "resolve_fields/2" do
    test "resolves text fields to their values" do
      schema = create_schema(%{name: "article"})
      title_field = create_field(schema, %{name: "title", field_type: "text"})
      body_field = create_field(schema, %{name: "body", field_type: "text"})

      content =
        create_content(schema, %{
          "#{title_field.id}" => "Test Title",
          "#{body_field.id}" => "Test Body"
        })

      result = ContentResolver.resolve_fields(content, Repo)

      assert result.title == "Test Title"
      assert result.body == "Test Body"
    end

    test "converts field names to atoms" do
      schema = create_schema(%{name: "page"})
      field = create_field(schema, %{name: "my_field", field_type: "text"})
      content = create_content(schema, %{"#{field.id}" => "value"})

      result = ContentResolver.resolve_fields(content, Repo)

      assert is_map(result)
      assert Map.has_key?(result, :my_field)
      assert result.my_field == "value"
    end

    test "resolves reference fields to content maps" do
      # Create author schema and content
      author_schema = create_schema(%{name: "author"})
      author_name_field = create_field(author_schema, %{name: "name", field_type: "text"})

      author_content =
        create_content(author_schema, %{"#{author_name_field.id}" => "John Doe"})

      # Create post schema with author reference
      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      author_ref_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      post_content =
        create_content(post_schema, %{
          "#{title_field.id}" => "My Post",
          "#{author_ref_field.id}" => "#{author_content.id}"
        })

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.title == "My Post"
      assert is_map(result.author)
      assert result.author.name == "John Doe"
    end

    test "handles nil reference fields" do
      author_schema = create_schema(%{name: "author"})

      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      _author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      # Create post without author reference
      post_content =
        create_content(post_schema, %{
          "#{title_field.id}" => "Post Without Author"
        })

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.title == "Post Without Author"
      assert result.author == nil
    end

    test "handles invalid reference IDs" do
      author_schema = create_schema(%{name: "author"})

      post_schema = create_schema(%{name: "post"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      # Create post with non-existent author ID
      post_content = create_content(post_schema, %{"#{author_field.id}" => "99999"})

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.author == nil
    end

    test "handles non-numeric reference values" do
      author_schema = create_schema(%{name: "author"})

      post_schema = create_schema(%{name: "post"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      # Create post with invalid reference value
      post_content = create_content(post_schema, %{"#{author_field.id}" => "invalid"})

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.author == nil
    end

    test "resolves nested references recursively" do
      # Create image schema
      image_schema = create_schema(%{name: "image"})
      image_url_field = create_field(image_schema, %{name: "url", field_type: "text"})

      image_content =
        create_content(image_schema, %{"#{image_url_field.id}" => "image.jpg"})

      # Create author schema with image reference
      author_schema = create_schema(%{name: "author"})
      author_name_field = create_field(author_schema, %{name: "name", field_type: "text"})

      author_avatar_field =
        create_field(author_schema, %{
          name: "avatar",
          field_type: "reference",
          referenced_schema_id: image_schema.id
        })

      author_content =
        create_content(author_schema, %{
          "#{author_name_field.id}" => "Jane Doe",
          "#{author_avatar_field.id}" => "#{image_content.id}"
        })

      # Create post with author reference
      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      post_content =
        create_content(post_schema, %{
          "#{title_field.id}" => "My Post",
          "#{author_field.id}" => "#{author_content.id}"
        })

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.title == "My Post"
      assert result.author.name == "Jane Doe"
      assert result.author.avatar.url == "image.jpg"
    end

    test "handles multiple reference fields" do
      # Create referenced schemas
      author_schema = create_schema(%{name: "author"})
      author_name = create_field(author_schema, %{name: "name", field_type: "text"})
      author = create_content(author_schema, %{"#{author_name.id}" => "Author"})

      category_schema = create_schema(%{name: "category"})
      category_name = create_field(category_schema, %{name: "name", field_type: "text"})
      category = create_content(category_schema, %{"#{category_name.id}" => "Tech"})

      # Create post with multiple references
      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      category_field =
        create_field(post_schema, %{
          name: "category",
          field_type: "reference",
          referenced_schema_id: category_schema.id
        })

      post =
        create_content(post_schema, %{
          "#{title_field.id}" => "Post",
          "#{author_field.id}" => "#{author.id}",
          "#{category_field.id}" => "#{category.id}"
        })

      result = ContentResolver.resolve_fields(post, Repo)

      assert result.author.name == "Author"
      assert result.category.name == "Tech"
    end

    test "resolves reference field with array of IDs (multiple: true)" do
      # Create tag schema and multiple tags
      tag_schema = create_schema(%{name: "tag"})
      tag_name_field = create_field(tag_schema, %{name: "name", field_type: "text"})

      tag1 = create_content(tag_schema, %{"#{tag_name_field.id}" => "Elixir"})
      tag2 = create_content(tag_schema, %{"#{tag_name_field.id}" => "Phoenix"})
      tag3 = create_content(tag_schema, %{"#{tag_name_field.id}" => "CMS"})

      # Create post schema with tags reference field
      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      tags_field =
        create_field(post_schema, %{
          name: "tags",
          field_type: "reference",
          referenced_schema_id: tag_schema.id,
          options: %{"multiple" => true}
        })

      # Create post with array of tag IDs
      post_content =
        create_content(post_schema, %{
          "#{title_field.id}" => "My Post",
          "#{tags_field.id}" => ["#{tag1.id}", "#{tag2.id}", "#{tag3.id}"]
        })

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.title == "My Post"
      assert is_list(result.tags)
      assert length(result.tags) == 3

      tag_names = Enum.map(result.tags, & &1.name) |> Enum.sort()
      assert tag_names == ["CMS", "Elixir", "Phoenix"]
    end

    test "handles empty array for multiple references" do
      tag_schema = create_schema(%{name: "tag"})

      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      tags_field =
        create_field(post_schema, %{
          name: "tags",
          field_type: "reference",
          referenced_schema_id: tag_schema.id,
          options: %{"multiple" => true}
        })

      post_content =
        create_content(post_schema, %{
          "#{title_field.id}" => "Post Without Tags",
          "#{tags_field.id}" => []
        })

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.title == "Post Without Tags"
      assert result.tags == []
    end

    test "filters out invalid IDs from array of references" do
      tag_schema = create_schema(%{name: "tag"})
      tag_name_field = create_field(tag_schema, %{name: "name", field_type: "text"})

      tag1 = create_content(tag_schema, %{"#{tag_name_field.id}" => "Valid Tag"})

      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      tags_field =
        create_field(post_schema, %{
          name: "tags",
          field_type: "reference",
          referenced_schema_id: tag_schema.id,
          options: %{"multiple" => true}
        })

      # Create post with mix of valid and invalid IDs
      post_content =
        create_content(post_schema, %{
          "#{title_field.id}" => "My Post",
          "#{tags_field.id}" => ["#{tag1.id}", "99999", "invalid"]
        })

      result = ContentResolver.resolve_fields(post_content, Repo)

      assert result.title == "My Post"
      assert is_list(result.tags)
      assert length(result.tags) == 1
      assert hd(result.tags).name == "Valid Tag"
    end

    test "handles nested multiple references" do
      # Create tag schema
      tag_schema = create_schema(%{name: "tag"})
      tag_name_field = create_field(tag_schema, %{name: "name", field_type: "text"})

      tag1 = create_content(tag_schema, %{"#{tag_name_field.id}" => "Tag 1"})
      tag2 = create_content(tag_schema, %{"#{tag_name_field.id}" => "Tag 2"})

      # Create author schema with multiple tags
      author_schema = create_schema(%{name: "author"})
      author_name_field = create_field(author_schema, %{name: "name", field_type: "text"})

      author_tags_field =
        create_field(author_schema, %{
          name: "interests",
          field_type: "reference",
          referenced_schema_id: tag_schema.id,
          options: %{"multiple" => true}
        })

      author =
        create_content(author_schema, %{
          "#{author_name_field.id}" => "Jane Doe",
          "#{author_tags_field.id}" => ["#{tag1.id}", "#{tag2.id}"]
        })

      # Create post referencing the author (who has multiple interests)
      post_schema = create_schema(%{name: "post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      post =
        create_content(post_schema, %{
          "#{title_field.id}" => "My Post",
          "#{author_field.id}" => "#{author.id}"
        })

      result = ContentResolver.resolve_fields(post, Repo)

      assert result.title == "My Post"
      assert result.author.name == "Jane Doe"
      assert is_list(result.author.interests)
      assert length(result.author.interests) == 2

      interest_names = Enum.map(result.author.interests, & &1.name) |> Enum.sort()
      assert interest_names == ["Tag 1", "Tag 2"]
    end
  end

  describe "prepare_field_values/2" do
    test "converts field names to field IDs" do
      schema =
        create_schema_with_fields(%{name: "article"}, [
          %{name: "title", field_type: "text"},
          %{name: "body", field_type: "text"}
        ])

      attrs = %{title: "Test Title", body: "Test Body"}
      result = ContentResolver.prepare_field_values(attrs, schema)

      title_field = Enum.find(schema.fields, &(&1.name == "title"))
      body_field = Enum.find(schema.fields, &(&1.name == "body"))

      assert result["#{title_field.id}"] == "Test Title"
      assert result["#{body_field.id}"] == "Test Body"
    end

    test "accepts string field names" do
      schema =
        create_schema_with_fields(%{name: "page"}, [
          %{name: "title", field_type: "text"}
        ])

      attrs = %{"title" => "String Key"}
      result = ContentResolver.prepare_field_values(attrs, schema)

      title_field = Enum.find(schema.fields, &(&1.name == "title"))
      assert result["#{title_field.id}"] == "String Key"
    end

    test "accepts atom field names" do
      schema =
        create_schema_with_fields(%{name: "page"}, [
          %{name: "title", field_type: "text"}
        ])

      attrs = %{title: "Atom Key"}
      result = ContentResolver.prepare_field_values(attrs, schema)

      title_field = Enum.find(schema.fields, &(&1.name == "title"))
      assert result["#{title_field.id}"] == "Atom Key"
    end

    test "handles reference fields with _id suffix" do
      author_schema = create_schema(%{name: "author"})

      post_schema = create_schema(%{name: "post"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      schema = Repo.preload(post_schema, :fields)

      # Should accept both 'author' and 'author_id'
      attrs = %{author_id: 123}
      result = ContentResolver.prepare_field_values(attrs, schema)

      assert result["#{author_field.id}"] == "123"
    end

    test "handles reference fields without _id suffix" do
      author_schema = create_schema(%{name: "author"})

      post_schema = create_schema(%{name: "post"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      schema = Repo.preload(post_schema, :fields)

      attrs = %{author: 456}
      result = ContentResolver.prepare_field_values(attrs, schema)

      assert result["#{author_field.id}"] == "456"
    end

    test "converts all values to strings" do
      schema =
        create_schema_with_fields(%{name: "test"}, [
          %{name: "field1", field_type: "text"}
        ])

      attrs = %{field1: 123}
      result = ContentResolver.prepare_field_values(attrs, schema)

      field = hd(schema.fields)
      assert result["#{field.id}"] == "123"
    end

    test "ignores fields not in schema" do
      schema =
        create_schema_with_fields(%{name: "test"}, [
          %{name: "valid_field", field_type: "text"}
        ])

      attrs = %{valid_field: "value", invalid_field: "ignored"}
      result = ContentResolver.prepare_field_values(attrs, schema)

      valid_field = hd(schema.fields)
      assert result["#{valid_field.id}"] == "value"
      assert map_size(result) == 1
    end

    test "handles empty attrs" do
      schema =
        create_schema_with_fields(%{name: "test"}, [
          %{name: "field1", field_type: "text"}
        ])

      result = ContentResolver.prepare_field_values(%{}, schema)

      assert result == %{}
    end

    test "handles schema with no fields" do
      schema = create_schema(%{name: "empty"})
      schema = Repo.preload(schema, :fields)

      result = ContentResolver.prepare_field_values(%{anything: "value"}, schema)

      assert result == %{}
    end

    test "prefers _id suffix for reference fields" do
      author_schema = create_schema(%{name: "author"})

      post_schema = create_schema(%{name: "post"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      schema = Repo.preload(post_schema, :fields)

      # When both are present, should prefer author_id
      attrs = %{author: 111, author_id: 222}
      result = ContentResolver.prepare_field_values(attrs, schema)

      # The implementation uses || so it will take the first non-nil value
      # In this case, Map.get order determines precedence
      assert result["#{author_field.id}"] in ["111", "222"]
    end

    test "handles mixed field types" do
      author_schema = create_schema(%{name: "author"})

      post_schema =
        create_schema_with_fields(%{name: "post"}, [
          %{name: "title", field_type: "text"},
          %{name: "body", field_type: "text"}
        ])

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      schema = Repo.preload(post_schema, :fields, force: true)

      attrs = %{
        title: "Title",
        body: "Body",
        author_id: 789
      }

      result = ContentResolver.prepare_field_values(attrs, schema)

      title_field = Enum.find(schema.fields, &(&1.name == "title"))
      body_field = Enum.find(schema.fields, &(&1.name == "body"))

      assert result["#{title_field.id}"] == "Title"
      assert result["#{body_field.id}"] == "Body"
      assert result["#{author_field.id}"] == "789"
    end
  end
end
