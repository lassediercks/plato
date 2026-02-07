defmodule Examples.BlogSchemas do
  @moduledoc """
  Example schema definitions demonstrating multiline text field options.

  This module shows how to define content schemas with various field types,
  including multiline text fields that render as textareas in the admin UI.

  ## Usage

  To sync these schemas to the database:

      Plato.sync_schemas(Examples.BlogSchemas, otp_app: :my_app)

  ## Field Options

  Text fields support the following options:

    * `multiline: true` - Renders the field as a textarea (100% width, 250px height)

  """

  use Plato.SchemaBuilder

  @doc """
  Homepage schema - a unique singleton for site-wide content.
  """
  schema "homepage", unique: true do
    field :title, :text
    field :tagline, :text, multiline: true
    field :welcome_message, :text, multiline: true
  end

  @doc """
  Blog post schema with various text fields.
  """
  schema "blog-post" do
    field :title, :text
    field :slug, :text
    field :excerpt, :text, multiline: true
    field :body, :text, multiline: true
    field :author, :reference, to: "author"
    field :featured_image, :reference, to: "image"
  end

  @doc """
  Author schema for blog authors.
  """
  schema "author" do
    field :name, :text
    field :email, :text
    field :bio, :text, multiline: true
    field :avatar, :reference, to: "image"
  end

  @doc """
  Image schema for managing uploaded images.
  """
  schema "image" do
    field :url, :text
    field :alt_text, :text
    field :caption, :text, multiline: true
  end

  @doc """
  Comment schema for blog post comments.
  """
  schema "comment" do
    field :author_name, :text
    field :email, :text
    field :content, :text, multiline: true
    field :post, :reference, to: "blog-post"
  end

  @doc """
  FAQ schema for frequently asked questions.
  """
  schema "faq" do
    field :question, :text
    field :answer, :text, multiline: true
  end

  @doc """
  Testimonial schema for customer testimonials.
  """
  schema "testimonial" do
    field :customer_name, :text
    field :company, :text
    field :quote, :text, multiline: true
    field :image, :reference, to: "image"
  end
end
