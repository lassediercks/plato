defmodule PlatoDemo.ContentSchemas do
  @moduledoc """
  CMS schema definitions for the demo app.

  These schemas are defined in code and synced to the database on app start.
  They demonstrate how to use Plato's SchemaBuilder DSL.
  """

  use Plato.SchemaBuilder

  # Singleton schema for site header
  schema "site-header", unique: true do
    field :logo_text, :text, as_title: true
    field :tagline, :text
  end

  # Singleton schema for homepage
  schema "homepage", unique: true do
    field :hero_title, :text, as_title: true
    field :hero_subtitle, :text
    field :cta_text, :text
    field :cta_link, :text
  end

  # Multiple instances allowed
  schema "blog-post" do
    field :title, :text, as_title: true
    field :slug, :text
    field :body, :richtext
    field :excerpt, :text
    field :author, :reference, to: "author"
  end

  schema "author" do
    field :name, :text, as_title: true
    field :bio, :text
    field :email, :text
  end
end
