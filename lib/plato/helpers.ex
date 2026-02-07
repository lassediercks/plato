defmodule Plato.Helpers do
  @moduledoc """
  View helpers for rendering Plato content in Phoenix templates.

  ## Usage

  In your view or `my_app_web.ex`:

      import Plato.Helpers

  Then in your templates:

      <%= plato_content("homepage", :title, otp_app: :my_app) %>

      <%= plato_list("blog_post", otp_app: :my_app) do |post| %>
        <article>
          <h2><%= post.title %></h2>
        </article>
      <% end %>
  """

  @doc """
  Fetch and return a field value from unique content.

  Returns the field value if found, `nil` otherwise.

  ## Examples

  In templates:

      <%= plato_content("homepage", :title, otp_app: :my_app) %>
      #=> "Welcome to My Site"

      <%= plato_content("homepage", :tagline, otp_app: :my_app) %>
      #=> "The best site ever"

  Returns nil for missing content:

      iex> Plato.Helpers.plato_content("nonexistent", :title, repo: Plato.Repo)
      nil
  """
  @spec plato_content(String.t(), atom(), keyword()) :: any()
  def plato_content(schema_name, field_name, opts \\ []) do
    case Plato.get_content(schema_name, opts) do
      {:ok, content} -> Map.get(content, field_name)
      {:error, _} -> nil
    end
  end

  @doc """
  Fetch content and render it with a function.

  Useful when you need to render referenced content with custom markup.

  ## Examples

      <%= plato_render("homepage", :hero, otp_app: :my_app, fn hero -> %>
        <img src="<%= hero.image_url %>" alt="<%= hero.alt_text %>" />
      <% end) %>
  """
  @spec plato_render(String.t(), atom(), keyword(), (any() -> any())) :: any()
  def plato_render(schema_name, field_name, opts \\ [], fun) when is_function(fun, 1) do
    case plato_content(schema_name, field_name, opts) do
      nil -> nil
      content -> fun.(content)
    end
  end

  @doc """
  List all content for a schema and render each item with a function.

  ## Examples

      <%= plato_list("blog_post", otp_app: :my_app, fn post -> %>
        <article>
          <h2><%= post.title %></h2>
          <p><%= post.excerpt %></p>
        </article>
      <% end) %>
  """
  @spec plato_list(String.t(), keyword(), (any() -> any())) :: [any()]
  def plato_list(schema_name, opts \\ [], fun) when is_function(fun, 1) do
    case Plato.list_content(schema_name, opts) do
      {:ok, items} -> Enum.map(items, fun)
      {:error, _} -> []
    end
  end
end
