# Plato Tests

This directory contains comprehensive tests for the Plato CMS library.

## Test Structure

- `test/plato_test.exs` - Main Plato API tests
- `test/plato_schema_test.exs` - Schema model tests
- `test/plato/field_test.exs` - Field model tests
- `test/plato/content_test.exs` - Content model tests
- `test/plato/content_resolver_test.exs` - Content resolver tests
- `test/plato/schema_builder_test.exs` - SchemaBuilder DSL tests
- `test/support/data_case.ex` - Shared test setup with database sandbox
- `test/support/test_helpers.ex` - Helper functions for creating test data

## Running Tests

### Prerequisites

Tests require a PostgreSQL database. You can run one using Docker:

```bash
cd apps/plato
docker-compose -f docker-compose.test.yml up -d
```

This will start a PostgreSQL instance on port 5433.

### Setup Database

Create and migrate the test database:

```bash
cd apps/plato
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
```

### Run All Tests

```bash
cd apps/plato
mix test
```

### Run Specific Test File

```bash
mix test test/plato_test.exs
```

### Run Specific Test

```bash
mix test test/plato_test.exs:22
```

### Cleanup

Stop the test database when done:

```bash
docker-compose -f docker-compose.test.yml down
```

## Test Coverage

The test suite covers:

### Main API (`Plato` module)
- ✅ `get_content/2` - Success and error cases
- ✅ `get_content!/2` - Success and raises on error
- ✅ `list_content/2` - Multiple content instances
- ✅ `get_content_by_id/2` - By ID lookup with reference resolution
- ✅ `create_content/3` - Creating content with text and reference fields
- ✅ `update_content/3` - Updating existing content
- ✅ `sync_schemas/2` - Syncing code-defined schemas to database

### SchemaBuilder DSL
- ✅ Schema definition compilation
- ✅ Field definitions (text and reference types)
- ✅ Schema options (unique: true)
- ✅ Multiple schemas in one module
- ✅ Field ordering preservation

### ContentResolver
- ✅ Resolving text fields
- ✅ Resolving reference fields
- ✅ Nested reference resolution
- ✅ Handling nil references
- ✅ Field value preparation for storage
- ✅ Converting field names to IDs

### Models

#### Schema
- ✅ Changeset validation
- ✅ Required fields
- ✅ Field defaults (unique, managed_by)
- ✅ Creating and updating
- ✅ Database constraints
- ✅ Associations (has_many fields)

#### Field
- ✅ Text field creation
- ✅ Reference field creation
- ✅ Field type validation
- ✅ Reference field requirements
- ✅ Associations (belongs_to schema and referenced_schema)
- ✅ Cascade deletion behavior

#### Content
- ✅ Content creation with field values
- ✅ Field values as map storage
- ✅ Content updates
- ✅ Associations with schema
- ✅ Database constraints

## Configuration

Test database configuration is in `config/config.exs` and uses these environment variables:

- `POSTGRES_USER` (default: "postgres")
- `POSTGRES_PASSWORD` (default: "postgres")
- `POSTGRES_HOST` (default: "localhost")
- `POSTGRES_PORT` (default: "5433")

## Writing Tests

### Using DataCase

Most tests should use `Plato.DataCase` which provides:

- Database sandbox for test isolation
- Automatic cleanup after each test
- Helper imports (Ecto.Query, Ecto.Changeset)
- Test helper functions

```elixir
defmodule MyTest do
  use Plato.DataCase, async: true

  test "creates a schema" do
    schema = create_schema(%{name: "test"})
    assert schema.name == "test"
  end
end
```

### Test Helpers

Available helper functions:

- `create_schema/1` - Creates a schema with default or provided attributes
- `create_field/2` - Creates a field for a schema
- `create_content/2` - Creates content for a schema
- `create_schema_with_fields/2` - Creates a schema with fields in one call
- `errors_on/1` - Extracts errors from a changeset

### Async Tests

Tests using `Plato.DataCase` can be run asynchronously:

```elixir
use Plato.DataCase, async: true
```

This significantly speeds up test execution.
