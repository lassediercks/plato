defmodule PlatoDemoWeb.Router do
  use PlatoDemoWeb, :router
  import Plato.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PlatoDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PlatoDemoWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/blog/:slug", PageController, :blog_post
  end

  # Mount Plato CMS admin
  scope "/" do
    pipe_through :browser
    plato_admin "/admin/cms", otp_app: :plato_demo
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlatoDemoWeb do
  #   pipe_through :api
  # end
end
