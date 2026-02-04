defmodule PlatoWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, html: {PlatoWeb.Layouts, :root}
  end

  scope "/", PlatoWeb do
    pipe_through :browser

    get "/", SchemaController, :index
    post "/", SchemaController, :create
    get "/schemas/:id", SchemaController, :show
    post "/schemas/:schema_id/fields", FieldController, :create

    get "/content", ContentController, :index
    get "/content/new", ContentController, :new
    post "/content", ContentController, :create
    get "/content/:id", ContentController, :show
  end
end
