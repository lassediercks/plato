# Plato

A schema-driven headless CMS for Phoenix applications. Create dynamic content types, manage relationships, and query content with a clean API. Includes a mountable admin UI for content management.

## Features

- **Schema-driven content**: Define content types dynamically through the admin UI
- **Field types**: Text fields and reference fields (relationships between content)
- **Unique schemas**: Mark schemas as singleton (only one content instance allowed)
- **Clean API**: Query content by schema name with automatic field resolution
- **View helpers**: Template-friendly functions for easy content rendering
- **Mountable admin**: Admin UI can be mounted at any path in your router
- **Multi-tenant ready**: Support for multiple Plato instances with different databases

## Try the Demo

This repository is an umbrella project. The demo app shows a complete integration.

### With Docker (Easiest)

```bash
git clone https://github.com/lassediercks/plato.git
cd plato
docker-compose up
```

This will:
1. Start PostgreSQL database
2. Run Plato library tests (ensures everything works)
3. Start the demo app (only if tests pass)

Visit:
- **Frontend with CMS content**: http://localhost:4500
- **Admin UI**: http://localhost:4500/admin/cms

### Without Docker

```bash
git clone https://github.com/lassediercks/plato.git
cd plato
mix deps.get

# Setup database
cd apps/plato_demo
mix ecto.create
mix ecto.migrate
mix plato.install
mix ecto.migrate

# Start server
cd ../..
mix phx.server
```

See [apps/plato_demo/](apps/plato_demo/) for full documentation.

## Installation

Add `plato` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plato, "~> 0.0.7"}
  ]
end
```

Install dependencies and migrations:

```bash
mix deps.get
mix plato.install
mix ecto.migrate
```

## Configuration

Configure Plato to use your application's repo in `config/config.exs`:

```elixir
config :my_app, :plato,
  repo: MyApp.Repo
```

Or set a default otp_app to avoid passing it as an option everywhere:

```elixir
config :plato,
  default_otp_app: :my_app
```

**Note:** Plato uses your application's repo - it does not start its own database connection. Make sure your repo is configured and started in your application's supervision tree.

## Mount Admin UI

Import the Plato router and mount the admin interface in your `router.ex`:

```elixir
# lib/my_app_web/router.ex
import Plato.Router

scope "/" do
  pipe_through :browser

  # Mount admin at any path you want (default recommended: /admin/cms)
  plato_admin "/admin/cms", otp_app: :my_app
end
```

Now visit `/admin/cms` to manage your content schemas.

## Usage

### Creating Schemas

You can create schemas in two ways:

#### 1. Via Admin UI

Use the admin UI to create schemas dynamically:

1. Visit `/admin/cms`
2. Create a "Homepage" schema with `unique: true`
3. Add fields: "title" (text), "tagline" (text)

#### 2. Via Code (Recommended for production)

Define schemas in your application code for version control and consistency:

```elixir
# lib/my_app/content_schemas.ex
defmodule MyApp.ContentSchemas do
  use Plato.SchemaBuilder

  schema "login-header", unique: true do
    field :title, :text
    field :tagline, :text
  end

  schema "blog-post" do
    field :title, :text
    field :body, :text
    field :author, :reference, to: "author"
  end

  schema "author" do
    field :name, :text
    field :bio, :text
  end
end
```

Then sync to database:

```elixir
# In application.ex start/2 callback
def start(_type, _args) do
  # ... supervisor setup ...

  # Sync CMS schemas on app start
  Plato.sync_schemas(MyApp.ContentSchemas, otp_app: :my_app)

  # ... rest of start function ...
end
```

Or in a migration:

```elixir
defmodule MyApp.Repo.Migrations.SyncCMSSchemas do
  use Ecto.Migration

  def up do
    Plato.sync_schemas(MyApp.ContentSchemas, repo: MyApp.Repo)
  end

  def down do
    # Schemas remain in database but can be manually deleted if needed
  end
end
```

**Benefits of code-defined schemas:**
- Version controlled with your application
- Can't be accidentally modified or deleted through UI
- Automatically synced across environments
- Content can still be managed through the admin UI

### Querying Content

#### Get unique content (singleton schemas)

```elixir
# In your controller
def index(conn, _params) do
  {:ok, homepage} = Plato.get_content("homepage", otp_app: :my_app)
  render(conn, :index, homepage: homepage)
end
```

```heex
<!-- In your template -->
<h1><%= @homepage.title %></h1>
<p><%= @homepage.tagline %></p>
```

#### List all content for a schema

```elixir
def blog(conn, _params) do
  {:ok, posts} = Plato.list_content("blog_post", otp_app: :my_app)
  render(conn, :blog, posts: posts)
end
```

```heex
<%= for post <- @posts do %>
  <article>
    <h2><%= post.title %></h2>
    <p><%= post.body %></p>
    <small>By <%= post.author.name %></small>
  </article>
<% end %>
```

#### Get content by ID

```elixir
{:ok, content} = Plato.get_content_by_id(1, otp_app: :my_app)
```

#### Create and update content

```elixir
# Create content
{:ok, post} = Plato.create_content("blog_post", %{
  title: "My First Post",
  body: "Content here...",
  author_id: 1  # ID of referenced content
}, otp_app: :my_app)

# Update content
{:ok, updated} = Plato.update_content(post_id, %{
  title: "Updated Title"
}, otp_app: :my_app)
```

### View Helpers

For even simpler template integration, use the view helpers:

```elixir
# lib/my_app_web/my_app_web.ex
def html do
  quote do
    use Phoenix.Component
    import Plato.Helpers
    # ...
  end
end
```

```heex
<!-- Fetch single field value -->
<h1><%= plato_content("homepage", :title, otp_app: :my_app) %></h1>

<!-- Render content with a function -->
<%= plato_render("homepage", :hero, otp_app: :my_app, fn hero -> %>
  <img src="<%= hero.url %>" alt="<%= hero.alt_text %>">
<% end) %>

<!-- List and render multiple items -->
<%= plato_list("blog_post", otp_app: :my_app, fn post -> %>
  <article>
    <h2><%= post.title %></h2>
    <p><%= post.body %></p>
  </article>
<% end) %>
```

## Admin UI Features

The admin interface provides:

- **Schemas**: Create and manage content types (via UI or code)
- **Fields**: Add text fields and references to other schemas
- **Content**: Create and edit content instances
- **Code-managed schemas**: Define schemas in code (read-only in UI)
- **Unique validation**: Prevent multiple instances of unique schemas
- **Reference resolution**: Automatically resolve and display referenced content
- **Field deletion**: Validate which content would be affected before deleting fields

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

### View Helpers

- `Plato.Helpers.plato_content/3` - Fetch single field value
- `Plato.Helpers.plato_render/4` - Fetch and render with function
- `Plato.Helpers.plato_list/3` - List and render multiple items

## Development

Run the development environment with Docker:

```bash
docker-compose up
```

Visit `http://localhost:4500` to see the application.

## License

MIT License - see [LICENSE](LICENSE) for details.
