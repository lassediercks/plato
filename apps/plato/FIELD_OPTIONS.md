# Field Options Guide

This guide explains how to use field options in Plato CMS, specifically for multiline text fields.

## Overview

Field options allow you to customize how fields are rendered and behave in the admin UI. The most common use case is making text fields render as multiline textareas instead of single-line inputs.

## Multiline Text Fields

### Basic Usage

To create a multiline text field, use the `multiline: true` option:

```elixir
defmodule MyApp.ContentSchemas do
  use Plato.SchemaBuilder

  schema "blog-post" do
    field :title, :text
    field :body, :text, multiline: true
  end
end
```

This will render the `body` field as a `<textarea>` instead of a text `<input>` in the admin UI. The textarea will be 100% width and 250px height with vertical resizing enabled.

## Admin UI Integration

### Creating Fields via UI

When creating fields through the admin UI:

1. Navigate to your schema
2. Select "Text Field" as the field type
3. Enter the field name
4. Check the "Multiline (use textarea)" checkbox
5. Click "Add"

### Field Display

Fields with the `multiline` option will display a badge in the schema view to indicate they are multiline fields.

## Content Forms

When creating or editing content, multiline fields automatically render as textareas:

- **Single-line text fields**: Render as `<input type="text">`
- **Multiline text fields**: Render as `<textarea>` with 100% width, 250px height, and vertical resizing

## Code Examples

### Complete Schema Example

```elixir
defmodule MyApp.ContentSchemas do
  use Plato.SchemaBuilder

  schema "homepage", unique: true do
    field :title, :text
    field :tagline, :text, multiline: true
    field :welcome_message, :text, multiline: true
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
    field :email, :text
    field :bio, :text, multiline: true
  end
end
```

### Syncing Schemas

Sync your schemas to the database:

```elixir
# In your application startup
Plato.sync_schemas(MyApp.ContentSchemas, otp_app: :my_app)

# Or in a migration
defmodule MyApp.Repo.Migrations.SyncCMSSchemas do
  use Ecto.Migration

  def up do
    Plato.sync_schemas(MyApp.ContentSchemas, repo: MyApp.Repo)
  end

  def down do
    # Schemas will remain but can be manually deleted if needed
  end
end
```

### Updating Field Options

When you update field options in your schema definition, re-running `sync_schemas/2` will update the existing fields:

```elixir
# Initial definition
schema "article" do
  field :content, :text
end

# Updated definition with multiline
schema "article" do
  field :content, :text, multiline: true
end

# Re-sync to apply changes
Plato.sync_schemas(MyApp.ContentSchemas, otp_app: :my_app)
```

## Database Schema

Field options are stored in the `options` column as a JSONB map in PostgreSQL:

```elixir
%Plato.Field{
  name: "body",
  field_type: "text",
  options: %{"multiline" => true}
}
```

### Empty Options

Fields without options have an empty map:

```elixir
%Plato.Field{
  name: "title",
  field_type: "text",
  options: %{}
}
```

## Backward Compatibility

All existing fields automatically get an empty `options` map (`%{}`), ensuring full backward compatibility. No manual migration of existing data is required.

## Future Options

While currently only multiline text fields are supported, the options system is designed to be extensible. Future options might include:

- Field validation rules
- Placeholder text
- Help text
- Default values
- Input masks
- Character limits

## API Reference

### SchemaBuilder Field Options

- `multiline: boolean` - Render as textarea (default: `false`)
  - Textareas are rendered with 100% width, 250px height, and vertical resizing enabled

### Field Controller

The field controller automatically extracts options from form submissions:

```elixir
# Form submission
%{
  "field_type" => "text",
  "name" => "body",
  "multiline" => "true"
}

# Converted to
%{
  "field_type" => "text",
  "name" => "body",
  "options" => %{"multiline" => true}
}
```

## Testing

Example tests for field options:

```elixir
test "creates field with multiline option" do
  attrs = %{
    schema_id: schema.id,
    name: "body",
    field_type: "text",
    options: %{"multiline" => true}
  }

  {:ok, field} = Field.create(attrs, Repo)
  assert field.options == %{"multiline" => true}
end
```

See `test/plato/field_test.exs` for more examples.
