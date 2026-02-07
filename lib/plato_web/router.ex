defmodule PlatoWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_root_layout, html: {PlatoWeb.Layouts, :root})
  end

  scope "/", PlatoWeb do
    pipe_through(:browser)

    get("/", SchemaController, :index)
    post("/", SchemaController, :create)
    get("/schemas/:id", SchemaController, :show)
    post("/schemas/:schema_id/fields", FieldController, :create)
    post("/schemas/:schema_id/fields/reorder", FieldController, :reorder)
    get("/schemas/:schema_id/fields/:id/edit", FieldController, :edit)
    post("/schemas/:schema_id/fields/:id/update", FieldController, :update)
    get("/schemas/:schema_id/fields/:id/delete", FieldController, :delete_confirm)
    post("/schemas/:schema_id/fields/:id/delete", FieldController, :delete)

    get("/content", ContentController, :index)
    get("/content/new", ContentController, :new)
    post("/content", ContentController, :create)
    get("/content/:id", ContentController, :show)
    get("/content/:id/edit", ContentController, :edit)
    post("/content/:id/update", ContentController, :update)
  end
end
