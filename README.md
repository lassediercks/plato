# Plato

A schema-driven headless CMS for Phoenix applications. Create dynamic content types, manage relationships, and query content with a clean API. Includes a mountable admin UI for content management.

[![Hex.pm](https://img.shields.io/hexpm/v/plato.svg)](https://hex.pm/packages/plato)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/plato)

## Features

- **Schema-driven content**: Define content types dynamically through admin UI or code
- **Field types**: Text, rich text, images, and reference fields (relationships between content)
- **Image uploads**: Upload and manage images with S3-compatible storage
- **Field options**: Multiline text fields with customizable textarea rows
- **Unique schemas**: Mark schemas as singleton (only one content instance allowed)
- **Clean API**: Query content by schema name with automatic field resolution
- **View helpers**: Template-friendly functions for easy content rendering
- **Mountable admin**: Admin UI can be mounted at any path in your router
- **Multi-tenant ready**: Support for multiple Plato instances with different databases
- **Code-managed schemas**: Define schemas in code for version control and consistency

## Installation

Add `plato` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    # x-release-please-start-version
    {:plato, "~> 0.0.20"}
    # x-release-please-end
  ]
end
```

Install dependencies and migrations:

```bash
mix deps.get
mix plato.install
mix ecto.migrate
```

## Quick Start

For a complete working example with database setup, S3 configuration, and Docker support, see the [Plato Starter Repository](https://github.com/lassediercks/plato).

### 1. Configure Your Repo

Configure Plato to use your application's repo in `config/config.exs`:

```elixir
config :my_app, :plato,
  repo: MyApp.Repo
```

### 2. Mount the Admin UI

Import the Plato router and mount the admin interface in your `router.ex`:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import Plato.Router

  scope "/" do
    pipe_through :browser
    plato_admin "/admin/cms", otp_app: :my_app
  end
end
```

Visit `/admin/cms` to manage your content schemas.

### 3. Define Schemas in Code

Define schemas in your application for version control:

```elixir
defmodule MyApp.ContentSchemas do
  use Plato.SchemaBuilder

  schema "homepage", unique: true do
    field :title, :text
    field :tagline, :text
  end

  schema "blog-post" do
    field :title, :text
    field :slug, :text
    field :excerpt, :text, multiline: true
    field :body, :text, multiline: true
    field :author, :reference, to: "author"
  end

  schema "author" do
    field :name, :text
    field :bio, :text, multiline: true
  end
end
```

Sync schemas on application start in `application.ex`:

```elixir
def start(_type, _args) do
  children = [
    MyApp.Repo,
    # ... other children
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  {:ok, pid} = Supervisor.start_link(children, opts)

  # Sync CMS schemas after repo starts
  Plato.sync_schemas(MyApp.ContentSchemas, otp_app: :my_app)

  {:ok, pid}
end
```

### 4. Query Content

```elixir
# Get unique content (singleton schemas)
{:ok, homepage} = Plato.get_content("homepage", otp_app: :my_app)
homepage.title
#=> "Welcome to My Site"

# List all content for a schema
{:ok, posts} = Plato.list_content("blog-post", otp_app: :my_app)

# Get content by field value (e.g., slug lookup)
{:ok, post} = Plato.get_content_by_field("blog-post", "slug", "my-first-post", otp_app: :my_app)
```

### 5. Use in Templates

Import helpers in your view module:

```elixir
# lib/my_app_web.ex
def html do
  quote do
    use Phoenix.Component
    import Plato.Helpers
    # ...
  end
end
```

Use in templates:

```heex
<!-- Fetch single field value -->
<h1><%= plato_content("homepage", :title, otp_app: :my_app) %></h1>

<!-- List and render multiple items -->
<%= plato_list("blog-post", otp_app: :my_app, fn post -> %>
  <article>
    <h2><%= post.title %></h2>
    <p><%= post.excerpt %></p>
    <small>By <%= post.author.name %></small>
  </article>
<% end) %>
```

## Image Field Support (Optional)

To use image fields, you need S3-compatible storage. Add these dependencies to `mix.exs`:

```elixir
def deps do
  [
    # x-release-please-start-version
    {:plato, "~> 0.0.19"},
    # x-release-please-end


    # Required for image field support
    {:ex_aws, "~> 2.5"},
    {:ex_aws_s3, "~> 2.5"},
    {:hackney, "~> 1.20"}
  ]
end
```

Then configure storage in `config/config.exs` or `config/runtime.exs`:

```elixir
# For AWS S3
config :my_app, :plato,
  repo: MyApp.Repo,
  storage: [
    adapter: Plato.Storage.S3Adapter,
    bucket: "my-app-uploads",
    region: "us-east-1",
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    signed_url_expiry: 3600
  ]

# For SeaweedFS (local development)
config :my_app, :plato,
  repo: MyApp.Repo,
  storage: [
    adapter: Plato.Storage.S3Adapter,
    bucket: "plato-uploads",
    endpoint: "http://localhost:8333",
    access_key_id: "any-key",
    secret_access_key: "any-secret",
    region: "us-east-1"
  ]
```

For a complete local development setup with SeaweedFS and Docker, see the [Plato Starter Repository](https://github.com/lassediercks/plato).

**Note:** Without S3 configuration, image fields will not be available in the admin UI. You can still use text and reference fields.

## Documentation

- **[API Reference](https://hexdocs.pm/plato)** - Complete module and function documentation
- **[Starter Repository](https://github.com/lassediercks/plato)** - Full working example with Docker setup
- **[Changelog](CHANGELOG.md)** - Version history and breaking changes

### Key Modules

- `Plato` - Main API for querying and managing content
- `Plato.SchemaBuilder` - DSL for defining schemas in code
- `Plato.Helpers` - View helpers for templates
- `Plato.Router` - Admin UI mounting
- `Plato.Storage.S3Adapter` - S3-compatible storage backend

## Examples

See the [Plato Starter Repository](https://github.com/lassediercks/plato) for:

- Complete Phoenix application setup
- Schema definitions for blog, homepage, and author content
- S3/SeaweedFS configuration for local development
- Docker Compose setup
- Example queries and templates

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Documentation](https://hexdocs.pm/plato)
- [Hex.pm](https://hex.pm/packages/plato)
- [GitHub](https://github.com/lassediercks/plato)
- [Starter Repository](https://github.com/lassediercks/plato-starter)
