# Plato

A schema-driven headless CMS for Phoenix applications. Create dynamic content types, manage relationships, and query content with a clean API. Includes a mountable admin UI for content management.

[![Hex.pm](https://img.shields.io/hexpm/v/plato.svg)](https://hex.pm/packages/plato)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/plato)

## Features

- **Schema-driven content**: Define content types dynamically through admin UI or code
- **Field types**: Text fields and reference fields (relationships between content)
- **Field options**: Multiline text fields with customizable textarea rows
- **Unique schemas**: Mark schemas as singleton (only one content instance allowed)
- **Clean API**: Query content by schema name with automatic field resolution
- **View helpers**: Template-friendly functions for easy content rendering
- **Mountable admin**: Admin UI can be mounted at any path in your router
- **Multi-tenant ready**: Support for multiple Plato instances with different databases
- **Code-managed schemas**: Define schemas in code for version control and consistency

## Installation

Add `plato` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # x-release-please-start-version
    {:plato, "~> 0.0.11"}
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

### 1. Configure

Configure Plato to use your application's repo in `config/config.exs`:

```elixir
config :my_app, :plato,
  repo: MyApp.Repo
```

Or set a default otp_app:

```elixir
config :plato,
  default_otp_app: :my_app
```

**Note:** Plato uses your application's repo - it does not start its own database connection.

### 2. Mount Admin UI

Import the Plato router and mount the admin interface in your `router.ex`:

```elixir
# lib/my_app_web/router.ex
import Plato.Router

scope "/" do
  pipe_through :browser

  # Mount admin at any path you want
  plato_admin "/admin/cms", otp_app: :my_app
end
```

Now visit `/admin/cms` to manage your content schemas.

### 3. Define Schemas

#### Option A: Via Admin UI

1. Visit `/admin/cms`
2. Create a "Homepage" schema with `unique: true`
3. Add fields: "title" (text), "tagline" (text)

#### Option B: In Code (Recommended)

Define schemas in your application code for version control:

```elixir
# lib/my_app/content_schemas.ex
defmodule MyApp.ContentSchemas do
  use Plato.SchemaBuilder

  schema "homepage", unique: true do
    field :title, :text
    field :tagline, :text
  end

  schema "blog-post" do
    field :title, :text
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

Sync to database in your `application.ex`:

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

# Get content by ID
{:ok, post} = Plato.get_content_by_id(1, otp_app: :my_app)
```

### 5. Use View Helpers

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

<!-- Render content with a function -->
<%= plato_render("homepage", :hero, otp_app: :my_app, fn hero -> %>
  <img src="<%= hero.url %>" alt="<%= hero.alt_text %>">
<% end) %>

<!-- List and render multiple items -->
<%= plato_list("blog-post", otp_app: :my_app, fn post -> %>
  <article>
    <h2><%= post.title %></h2>
    <p><%= post.body %></p>
    <small>By <%= post.author.name %></small>
  </article>
<% end) %>
```

## API Reference

### Main Functions

- `Plato.sync_schemas/2` - Sync code-defined schemas to database
- `Plato.get_content/2` - Get unique content by schema name
- `Plato.get_content!/2` - Get unique content, raises on error
- `Plato.list_content/2` - List all content for a schema
- `Plato.get_content_by_id/2` - Get content by database ID
- `Plato.create_content/3` - Create new content
- `Plato.update_content/3` - Update existing content

### Schema Builder (DSL)

- `use Plato.SchemaBuilder` - Import schema definition macros
- `schema/2` - Define a schema with name and options
- `field/3` - Define a field within a schema
  - Field options for text fields:
    - `multiline: true` - Render as textarea instead of input (100% width, 250px height)

### View Helpers

- `Plato.Helpers.plato_content/3` - Fetch single field value
- `Plato.Helpers.plato_render/4` - Fetch and render with function
- `Plato.Helpers.plato_list/3` - List and render multiple items

## Admin UI Features

The admin interface provides:

- **Schemas**: Create and manage content types
- **Fields**: Add text fields and references to other schemas
  - Text fields support multiline option for textarea rendering (100% width, 250px height)
- **Content**: Create and edit content instances
  - Multiline fields automatically render as textareas
- **Code-managed schemas**: Read-only display for schemas defined in code
- **Unique validation**: Prevent multiple instances of unique schemas
- **Reference resolution**: Automatically resolve and display referenced content
- **Field deletion**: Validate which content would be affected before deleting fields

## Examples

See the [demo app](https://github.com/lassediercks/plato/tree/main/apps/plato_demo) for a complete working example.

## Development

This package is part of an umbrella project. To run tests:

```bash
cd apps/plato
docker-compose -f docker-compose.test.yml up -d
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

See [TESTING.md](TESTING.md) for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Documentation](https://hexdocs.pm/plato)
- [GitHub](https://github.com/lassediercks/plato)
- [Hex.pm](https://hex.pm/packages/plato)
