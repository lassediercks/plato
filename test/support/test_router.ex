defmodule PlatoWeb.TestRouter do
  @moduledoc false
  # Test router that properly mounts the admin interface at /admin

  use Phoenix.Router
  import Plato.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_root_layout, html: {PlatoWeb.Layouts, :root})
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)
    plato_admin("/admin", otp_app: :plato)
  end
end
