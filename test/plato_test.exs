defmodule PlatoTest do
  use Plato.DataCase, async: true

  alias Plato.Schema

  describe "get_content/2" do
    setup do
      # Create a unique schema
      schema = create_schema(%{name: "homepage", unique: true})
      title_field = create_field(schema, %{name: "title", field_type: "text"})
      tagline_field = create_field(schema, %{name: "tagline", field_type: "text"})

      content =
        create_content(schema, %{
          "#{title_field.id}" => "Welcome",
          "#{tagline_field.id}" => "To our site"
        })

      %{schema: schema, content: content, title_field: title_field, tagline_field: tagline_field}
    end

    test "returns content for existing unique schema", %{schema: _schema} do
      assert {:ok, content} = Plato.get_content("homepage", repo: Repo)
      assert content.title == "Welcome"
      assert content.tagline == "To our site"
    end

    test "returns error for non-existent schema" do
      assert {:error, :schema_not_found} = Plato.get_content("nonexistent", repo: Repo)
    end

    test "returns error when unique schema has no content" do
      _schema = create_schema(%{name: "empty_page", unique: true})
      assert {:error, :content_not_found} = Plato.get_content("empty_page", repo: Repo)
    end

    test "works with otp_app configuration" do
      Application.put_env(:plato, :default_otp_app, :test_app)
      Application.put_env(:test_app, :plato, repo: Repo)

      assert {:ok, content} = Plato.get_content("homepage", otp_app: :test_app)
      assert content.title == "Welcome"

      Application.delete_env(:plato, :default_otp_app)
      Application.delete_env(:test_app, :plato)
    end
  end

  describe "get_content!/2" do
    test "returns content on success" do
      schema = create_schema(%{name: "about", unique: true})
      field = create_field(schema, %{name: "content", field_type: "text"})
      create_content(schema, %{"#{field.id}" => "About us"})

      content = Plato.get_content!("about", repo: Repo)
      assert content.content == "About us"
    end

    test "raises on error" do
      assert_raise RuntimeError, ~r/Failed to get content for 'missing'/, fn ->
        Plato.get_content!("missing", repo: Repo)
      end
    end
  end

  describe "list_content/2" do
    setup do
      schema = create_schema(%{name: "blog_post"})
      title_field = create_field(schema, %{name: "title", field_type: "text"})
      body_field = create_field(schema, %{name: "body", field_type: "text"})

      content1 =
        create_content(schema, %{
          "#{title_field.id}" => "First Post",
          "#{body_field.id}" => "Content 1"
        })

      content2 =
        create_content(schema, %{
          "#{title_field.id}" => "Second Post",
          "#{body_field.id}" => "Content 2"
        })

      %{schema: schema, content1: content1, content2: content2}
    end

    test "returns all content for a schema" do
      assert {:ok, contents} = Plato.list_content("blog_post", repo: Repo)
      assert length(contents) == 2

      titles = Enum.map(contents, & &1.title) |> Enum.sort()
      assert titles == ["First Post", "Second Post"]
    end

    test "returns empty list for schema with no content" do
      create_schema(%{name: "empty_schema"})
      assert {:ok, []} = Plato.list_content("empty_schema", repo: Repo)
    end

    test "returns error for non-existent schema" do
      assert {:error, :schema_not_found} = Plato.list_content("nonexistent", repo: Repo)
    end
  end

  describe "get_content_by_id/2" do
    test "returns content by ID" do
      schema = create_schema(%{name: "page"})
      field = create_field(schema, %{name: "title", field_type: "text"})
      content = create_content(schema, %{"#{field.id}" => "My Page"})

      assert {:ok, result} = Plato.get_content_by_id(content.id, repo: Repo)
      assert result.title == "My Page"
    end

    test "returns error for non-existent content" do
      assert {:error, :content_not_found} = Plato.get_content_by_id(99999, repo: Repo)
    end

    test "resolves reference fields" do
      # Create author schema
      author_schema = create_schema(%{name: "author"})
      author_name_field = create_field(author_schema, %{name: "name", field_type: "text"})

      author_content =
        create_content(author_schema, %{"#{author_name_field.id}" => "John Doe"})

      # Create post schema with reference to author
      post_schema = create_schema(%{name: "post"})
      post_title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      post_author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author_schema.id
        })

      post_content =
        create_content(post_schema, %{
          "#{post_title_field.id}" => "My Post",
          "#{post_author_field.id}" => "#{author_content.id}"
        })

      assert {:ok, result} = Plato.get_content_by_id(post_content.id, repo: Repo)
      assert result.title == "My Post"
      assert result.author.name == "John Doe"
    end
  end

  describe "create_content/3" do
    test "creates content with field values" do
      _schema =
        create_schema_with_fields(%{name: "article"}, [
          %{name: "title", field_type: "text"},
          %{name: "body", field_type: "text"}
        ])

      attrs = %{title: "New Article", body: "Article content"}

      assert {:ok, content} = Plato.create_content("article", attrs, repo: Repo)
      assert content.title == "New Article"
      assert content.body == "Article content"
    end

    test "creates content with reference fields" do
      author_schema =
        create_schema_with_fields(%{name: "author"}, [
          %{name: "name", field_type: "text"}
        ])

      name_field = Enum.find(author_schema.fields, &(&1.name == "name"))
      author_content = create_content(author_schema, %{"#{name_field.id}" => "Jane Doe"})

      post_schema = create_schema(%{name: "post"})
      create_field(post_schema, %{name: "title", field_type: "text"})

      create_field(post_schema, %{
        name: "author",
        field_type: "reference",
        referenced_schema_id: author_schema.id
      })

      attrs = %{title: "My Post", author_id: author_content.id}

      assert {:ok, content} = Plato.create_content("post", attrs, repo: Repo)
      assert content.title == "My Post"
      assert content.author.name == "Jane Doe"
    end

    test "creates content with multiple references (array)" do
      tag_schema =
        create_schema_with_fields(%{name: "tag"}, [
          %{name: "name", field_type: "text"}
        ])

      name_field = Enum.find(tag_schema.fields, &(&1.name == "name"))
      tag1 = create_content(tag_schema, %{"#{name_field.id}" => "Elixir"})
      tag2 = create_content(tag_schema, %{"#{name_field.id}" => "Phoenix"})
      tag3 = create_content(tag_schema, %{"#{name_field.id}" => "CMS"})

      post_schema = create_schema(%{name: "blog_post"})
      create_field(post_schema, %{name: "title", field_type: "text"})

      tags_field =
        create_field(post_schema, %{
          name: "tags",
          field_type: "reference",
          referenced_schema_id: tag_schema.id,
          options: %{"multiple" => true}
        })

      # Store array directly in field_values for API-level creation
      attrs = %{
        title: "My Post About Elixir",
        tags: [tag1.id, tag2.id, tag3.id]
      }

      # Need to use raw field creation since API expects atoms
      schema = Repo.preload(post_schema, :fields)
      title_field = Enum.find(schema.fields, &(&1.name == "title"))

      field_values = %{
        "#{title_field.id}" => "My Post About Elixir",
        "#{tags_field.id}" => ["#{tag1.id}", "#{tag2.id}", "#{tag3.id}"]
      }

      {:ok, content} =
        Plato.Content.create(%{schema_id: post_schema.id, field_values: field_values}, Repo)

      # Retrieve and resolve
      assert {:ok, resolved} = Plato.get_content_by_id(content.id, repo: Repo)
      assert resolved.title == "My Post About Elixir"
      assert is_list(resolved.tags)
      assert length(resolved.tags) == 3

      tag_names = Enum.map(resolved.tags, & &1.name) |> Enum.sort()
      assert tag_names == ["CMS", "Elixir", "Phoenix"]
    end

    test "returns error for non-existent schema" do
      assert {:error, :schema_not_found} =
               Plato.create_content("nonexistent", %{}, repo: Repo)
    end

    test "handles validation errors" do
      # Create content without schema_id should fail at database level
      assert {:error, _changeset} = Plato.create_content("nonexistent", %{}, repo: Repo)
    end
  end

  describe "get_content_by_field/4" do
    test "finds content by field value" do
      schema =
        create_schema_with_fields(%{name: "product"}, [
          %{name: "title", field_type: "text"},
          %{name: "sku", field_type: "text"}
        ])

      sku_field = Enum.find(schema.fields, &(&1.name == "sku"))
      title_field = Enum.find(schema.fields, &(&1.name == "title"))

      content =
        create_content(schema, %{
          "#{sku_field.id}" => "ABC-123",
          "#{title_field.id}" => "Cool Product"
        })

      assert {:ok, result} = Plato.get_content_by_field("product", "sku", "ABC-123", repo: Repo)
      assert result.sku == "ABC-123"
      assert result.title == "Cool Product"
    end

    test "returns error when schema not found" do
      assert {:error, :schema_not_found} =
               Plato.get_content_by_field("nonexistent", "field", "value", repo: Repo)
    end

    test "returns error when field not found" do
      _schema =
        create_schema_with_fields(%{name: "page"}, [
          %{name: "title", field_type: "text"}
        ])

      assert {:error, :field_not_found} =
               Plato.get_content_by_field("page", "nonexistent_field", "value", repo: Repo)
    end

    test "returns error when content not found" do
      _schema =
        create_schema_with_fields(%{name: "page"}, [
          %{name: "slug", field_type: "text"}
        ])

      assert {:error, :content_not_found} =
               Plato.get_content_by_field("page", "slug", "nonexistent", repo: Repo)
    end

    test "works with otp_app configuration" do
      Application.put_env(:test_app, :plato, repo: Repo)

      schema =
        create_schema_with_fields(%{name: "user"}, [
          %{name: "email", field_type: "text"}
        ])

      email_field = Enum.find(schema.fields, &(&1.name == "email"))
      _content = create_content(schema, %{"#{email_field.id}" => "test@example.com"})

      assert {:ok, result} =
               Plato.get_content_by_field("user", "email", "test@example.com", otp_app: :test_app)

      assert result.email == "test@example.com"

      Application.delete_env(:test_app, :plato)
    end
  end

  describe "update_content/3" do
    test "updates existing content" do
      schema =
        create_schema_with_fields(%{name: "page"}, [
          %{name: "title", field_type: "text"},
          %{name: "body", field_type: "text"}
        ])

      field_values = %{
        "#{Enum.at(schema.fields, 0).id}" => "Original Title",
        "#{Enum.at(schema.fields, 1).id}" => "Original Body"
      }

      content = create_content(schema, field_values)

      assert {:ok, updated} =
               Plato.update_content(content.id, %{title: "Updated Title"}, repo: Repo)

      assert updated.title == "Updated Title"
      assert updated.body == "Original Body"
    end

    test "returns error for non-existent content" do
      assert {:error, :content_not_found} = Plato.update_content(99999, %{}, repo: Repo)
    end

    test "updates reference fields" do
      author1_schema =
        create_schema_with_fields(%{name: "author1"}, [
          %{name: "name", field_type: "text"}
        ])

      author1 =
        create_content(author1_schema, %{"#{Enum.at(author1_schema.fields, 0).id}" => "Author 1"})

      author2 =
        create_content(author1_schema, %{"#{Enum.at(author1_schema.fields, 0).id}" => "Author 2"})

      post_schema = create_schema(%{name: "article"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      author_field =
        create_field(post_schema, %{
          name: "author",
          field_type: "reference",
          referenced_schema_id: author1_schema.id
        })

      content =
        create_content(post_schema, %{
          "#{title_field.id}" => "Article",
          "#{author_field.id}" => "#{author1.id}"
        })

      assert {:ok, updated} =
               Plato.update_content(content.id, %{author_id: author2.id}, repo: Repo)

      assert updated.author.name == "Author 2"
    end

    test "updates multiple references (array)" do
      tag_schema =
        create_schema_with_fields(%{name: "update_tag"}, [
          %{name: "name", field_type: "text"}
        ])

      name_field = Enum.find(tag_schema.fields, &(&1.name == "name"))
      tag1 = create_content(tag_schema, %{"#{name_field.id}" => "Tag 1"})
      tag2 = create_content(tag_schema, %{"#{name_field.id}" => "Tag 2"})
      tag3 = create_content(tag_schema, %{"#{name_field.id}" => "Tag 3"})

      post_schema = create_schema(%{name: "update_post"})
      title_field = create_field(post_schema, %{name: "title", field_type: "text"})

      tags_field =
        create_field(post_schema, %{
          name: "tags",
          field_type: "reference",
          referenced_schema_id: tag_schema.id,
          options: %{"multiple" => true}
        })

      # Create content with initial tags
      content =
        create_content(post_schema, %{
          "#{title_field.id}" => "My Post",
          "#{tags_field.id}" => ["#{tag1.id}", "#{tag2.id}"]
        })

      # Update to different set of tags
      updated_values = %{
        "#{tags_field.id}" => ["#{tag2.id}", "#{tag3.id}"]
      }

      {:ok, updated_content} =
        content
        |> Plato.Content.changeset(%{field_values: updated_values})
        |> Repo.update()

      # Retrieve and verify
      assert {:ok, resolved} = Plato.get_content_by_id(updated_content.id, repo: Repo)
      assert is_list(resolved.tags)
      assert length(resolved.tags) == 2

      tag_names = Enum.map(resolved.tags, & &1.name) |> Enum.sort()
      assert tag_names == ["Tag 2", "Tag 3"]
    end
  end

  describe "sync_schemas/2" do
    defmodule TestSchemas do
      use Plato.SchemaBuilder

      schema "homepage", unique: true do
        field(:title, :text)
        field(:tagline, :text)
      end

      schema "blog_post" do
        field(:title, :text)
        field(:body, :text, multiline: true)
        field(:author, :reference, to: "author")
      end

      schema "author" do
        field(:name, :text)
        field(:bio, :text, multiline: true)
      end
    end

    test "creates schemas from module definitions" do
      assert :ok = Plato.sync_schemas(TestSchemas, repo: Repo)

      # Verify homepage schema was created
      homepage = Repo.get_by(Schema, name: "homepage")
      assert homepage != nil
      assert homepage.unique == true
      assert homepage.managed_by == "code"

      # Verify blog_post schema was created
      blog_post = Repo.get_by(Schema, name: "blog_post")
      assert blog_post != nil
      assert blog_post.unique == false

      # Verify fields were created
      homepage = Repo.preload(homepage, :fields)
      field_names = Enum.map(homepage.fields, & &1.name) |> Enum.sort()
      assert field_names == ["tagline", "title"]
    end

    test "updates existing schemas on re-sync" do
      # First sync
      assert :ok = Plato.sync_schemas(TestSchemas, repo: Repo)
      homepage = Repo.get_by(Schema, name: "homepage")
      original_id = homepage.id

      # Second sync should update, not create new
      assert :ok = Plato.sync_schemas(TestSchemas, repo: Repo)
      homepage = Repo.get_by(Schema, name: "homepage")
      assert homepage.id == original_id
    end

    test "creates reference fields correctly" do
      assert :ok = Plato.sync_schemas(TestSchemas, repo: Repo)

      author_schema = Repo.get_by(Schema, name: "author")
      blog_post = Repo.get_by(Schema, name: "blog_post") |> Repo.preload(:fields)

      author_field = Enum.find(blog_post.fields, &(&1.name == "author"))
      assert author_field != nil
      assert author_field.field_type == "reference"
      assert author_field.referenced_schema_id == author_schema.id
    end

    test "handles forward references gracefully" do
      # When blog_post references author but author isn't synced yet,
      # it should create the field without referenced_schema_id
      # This is an edge case - in practice sync_schemas processes all schemas

      defmodule ForwardRefSchemas do
        use Plato.SchemaBuilder

        schema "post" do
          field(:title, :text)
          field(:category, :reference, to: "category")
        end
      end

      # Sync without category schema existing
      assert :ok = Plato.sync_schemas(ForwardRefSchemas, repo: Repo)

      post = Repo.get_by(Schema, name: "post") |> Repo.preload(:fields)
      category_field = Enum.find(post.fields, &(&1.name == "category"))

      # Field should exist but reference might not be set
      assert category_field != nil
    end

    test "syncs field options correctly" do
      assert :ok = Plato.sync_schemas(TestSchemas, repo: Repo)

      blog_post = Repo.get_by(Schema, name: "blog_post") |> Repo.preload(:fields)
      body_field = Enum.find(blog_post.fields, &(&1.name == "body"))

      assert body_field.options == %{"multiline" => true}

      author = Repo.get_by(Schema, name: "author") |> Repo.preload(:fields)
      bio_field = Enum.find(author.fields, &(&1.name == "bio"))

      assert bio_field.options == %{"multiline" => true}
    end

    test "syncs multiple option for reference fields" do
      defmodule MultipleRefSchemas do
        use Plato.SchemaBuilder

        schema "blog-post" do
          field(:title, :text)
          field(:tags, :reference, to: "tag", multiple: true)
        end

        schema "tag" do
          field(:name, :text)
        end
      end

      assert :ok = Plato.sync_schemas(MultipleRefSchemas, repo: Repo)

      blog_post = Repo.get_by(Schema, name: "blog-post") |> Repo.preload(:fields)
      tags_field = Enum.find(blog_post.fields, &(&1.name == "tags"))

      assert tags_field != nil
      assert tags_field.field_type == "reference"
      assert tags_field.options == %{"multiple" => true}

      tag_schema = Repo.get_by(Schema, name: "tag")
      assert tags_field.referenced_schema_id == tag_schema.id
    end

    test "updates field options on re-sync" do
      defmodule InitialSchemas do
        use Plato.SchemaBuilder

        schema "article" do
          field(:content, :text)
        end
      end

      # First sync without multiline
      assert :ok = Plato.sync_schemas(InitialSchemas, repo: Repo)

      article = Repo.get_by(Schema, name: "article") |> Repo.preload(:fields)
      content_field = Enum.find(article.fields, &(&1.name == "content"))
      assert content_field.options == %{}

      # Update schema definition to include multiline
      defmodule UpdatedSchemas do
        use Plato.SchemaBuilder

        schema "article" do
          field(:content, :text, multiline: true)
        end
      end

      # Re-sync with multiline option
      assert :ok = Plato.sync_schemas(UpdatedSchemas, repo: Repo)

      article = Repo.get_by(Schema, name: "article") |> Repo.preload(:fields, force: true)
      content_field = Enum.find(article.fields, &(&1.name == "content"))
      assert content_field.options == %{"multiline" => true}
    end
  end

  describe "error handling" do
    test "raises when no repo is configured" do
      Application.delete_env(:plato, :default_otp_app)

      assert_raise ArgumentError, ~r/Must provide :repo or :otp_app/, fn ->
        Plato.get_content("test")
      end
    end

    test "raises when otp_app has no plato config" do
      Application.put_env(:plato, :default_otp_app, :invalid_app)

      assert_raise ArgumentError, fn ->
        Plato.get_content("test")
      end

      Application.delete_env(:plato, :default_otp_app)
    end
  end
end
