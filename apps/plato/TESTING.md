# Plato Testing Guide

## Overview

Plato now has comprehensive test coverage for all core functionality. The test suite includes unit tests for models, integration tests for the main API, and tests for the SchemaBuilder DSL.

## Quick Start

```bash
# 1. Start test database
cd apps/plato
docker-compose -f docker-compose.test.yml up -d

# 2. Setup database
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate

# 3. Run tests
mix test

# 4. Cleanup
docker-compose -f docker-compose.test.yml down
```

## Test Files

### Core API Tests

**`test/plato_test.exs`** - Main Plato module API tests
- Content retrieval (get_content, list_content, get_content_by_id)
- Content creation and updates
- Schema synchronization from code
- Error handling and configuration

### Model Tests

**`test/plato_schema_test.exs`** - Schema model
- Validation and changesets
- Database constraints (unique names)
- Associations with fields
- Managed schemas (UI vs code)

**`test/plato/field_test.exs`** - Field model
- Text and reference field types
- Field validation
- Schema associations
- Cascade deletion behavior
- Complex reference scenarios (self-references, circular references)

**`test/plato/content_test.exs`** - Content model
- Content creation with field values
- Map-based field value storage
- Content updates
- Database constraints and associations
- Querying content

### Business Logic Tests

**`test/plato/content_resolver_test.exs`** - ContentResolver module
- Converting database IDs to field names
- Resolving reference fields recursively
- Handling nil references
- Field value preparation for storage
- Mixed field types

**`test/plato/schema_builder_test.exs`** - SchemaBuilder DSL
- Schema macro compilation
- Field definitions
- Schema options (unique)
- Multiple schema definitions
- Real-world examples (blog, e-commerce)

## Test Infrastructure

### DataCase

**`test/support/data_case.ex`**

Provides shared test setup:
- Database sandbox configuration
- Automatic test isolation
- Helper imports
- Error handling utilities

Usage:
```elixir
defmodule MyTest do
  use Plato.DataCase, async: true

  test "my test" do
    # Test code with database access
  end
end
```

### Test Helpers

**`test/support/test_helpers.ex`**

Helper functions for creating test data:

```elixir
# Create a schema
schema = create_schema(%{name: "blog_post"})

# Create fields
title_field = create_field(schema, %{name: "title", field_type: "text"})

# Create content
content = create_content(schema, %{"#{title_field.id}" => "My Post"})

# Create schema with fields in one call
schema = create_schema_with_fields(%{name: "article"}, [
  %{name: "title", field_type: "text"},
  %{name: "body", field_type: "text"}
])
```

## Configuration

### Database Configuration

Test database config in `config/config.exs`:

```elixir
config :plato, Plato.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5433"),
  database: "plato_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
```

### Test Database

Docker Compose configuration in `docker-compose.test.yml`:
- PostgreSQL 16 Alpine
- Port 5433 (to avoid conflicts with default PostgreSQL)
- Temporary storage (tmpfs) for speed
- Health checks

## Test Statistics

Total test files: 7
- Main API: 1 file (10+ test cases)
- Models: 3 files (30+ test cases each)
- Business logic: 2 files (20+ test cases each)
- DSL: 1 file (15+ test cases)

All tests run with database sandbox for isolation and can run asynchronously for speed.

## Coverage Areas

### ✅ Fully Covered

1. **Main API** (`Plato` module)
   - All public functions tested
   - Success and error paths
   - Configuration handling

2. **Models** (`Schema`, `Field`, `Content`)
   - CRUD operations
   - Validations
   - Database constraints
   - Associations
   - Cascade behavior

3. **ContentResolver**
   - Field resolution
   - Reference resolution (including nested)
   - Field value preparation

4. **SchemaBuilder DSL**
   - Schema compilation
   - Field definitions
   - Options handling

### Edge Cases Covered

- Nil references
- Invalid reference IDs
- Circular references
- Self-referencing schemas
- Multiple references to same schema
- Empty schemas and field values
- Forward references
- Concurrent schema definitions

## Best Practices

### Test Isolation

All tests use database sandbox:
```elixir
use Plato.DataCase, async: true
```

This ensures:
- Each test runs in a transaction
- Changes are rolled back after test
- Tests can run in parallel
- No test pollution

### Descriptive Tests

Tests follow a clear structure:
```elixir
describe "function_name/arity" do
  test "describes what it does" do
    # Arrange
    schema = create_schema(%{name: "test"})

    # Act
    result = Plato.get_content("test", repo: Repo)

    # Assert
    assert {:ok, content} = result
    assert content.name == "test"
  end
end
```

### Setup Blocks

Use setup for common data:
```elixir
describe "content operations" do
  setup do
    schema = create_schema(%{name: "test"})
    field = create_field(schema, %{name: "title", field_type: "text"})
    %{schema: schema, field: field}
  end

  test "creates content", %{schema: schema, field: field} do
    # Use schema and field from setup
  end
end
```

## Continuous Integration

To integrate with CI:

```yaml
# Example GitHub Actions
test:
  services:
    postgres:
      image: postgres:16-alpine
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: plato_test
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5

  steps:
    - uses: actions/checkout@v2
    - uses: erlef/setup-beam@v1
      with:
        otp-version: '26'
        elixir-version: '1.18'
    - run: mix deps.get
    - run: cd apps/plato && MIX_ENV=test mix ecto.create
    - run: cd apps/plato && MIX_ENV=test mix ecto.migrate
    - run: cd apps/plato && mix test
```

## Troubleshooting

### Database Connection Issues

If you get database connection errors:

1. Ensure test database is running:
   ```bash
   docker-compose -f docker-compose.test.yml ps
   ```

2. Check port availability:
   ```bash
   lsof -i :5433
   ```

3. Verify environment variables:
   ```bash
   echo $POSTGRES_PORT
   ```

### Test Failures

If tests fail:

1. Check migrations are up to date:
   ```bash
   MIX_ENV=test mix ecto.migrate
   ```

2. Reset test database:
   ```bash
   MIX_ENV=test mix ecto.drop
   MIX_ENV=test mix ecto.create
   MIX_ENV=test mix ecto.migrate
   ```

3. Run tests with more output:
   ```bash
   mix test --trace
   ```

## Future Enhancements

Potential areas for additional testing:
- Performance tests for large datasets
- Concurrent access scenarios
- Integration tests with Phoenix
- Load testing for the admin UI
- Error recovery scenarios
- Migration rollback tests
