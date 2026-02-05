# Plato Demo

This is a full Phoenix application demonstrating how to integrate Plato CMS.

## Running the Demo

From the umbrella root:

```bash
# Install dependencies
mix deps.get

# Create and migrate database
cd apps/plato_demo
mix ecto.create
mix ecto.migrate

# Copy Plato migrations (first time only)
mix plato.install
mix ecto.migrate

# Start the server
cd ../..
mix phx.server
```

Visit:
- **Frontend**: http://localhost:4500 (Docker) or http://localhost:4000 (local)
- **CMS Admin**: http://localhost:4500/admin/cms (Docker) or http://localhost:4000/admin/cms (local)
