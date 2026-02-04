defmodule PlatoWeb.Layouts do
  use PlatoWeb, :html

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>Plato - Schema Creator</title>
        <link rel="stylesheet" href="/css/app.css"/>
      </head>
      <body>
        <%= if get_flash(@conn, :info) do %>
          <div class="flash info">
            <%= get_flash(@conn, :info) %>
          </div>
        <% end %>
        <%= if get_flash(@conn, :error) do %>
          <div class="flash error">
            <%= get_flash(@conn, :error) %>
          </div>
        <% end %>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end
