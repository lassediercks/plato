defmodule PlatoWeb do
  def html do
    quote do
      use Phoenix.Component
      import Phoenix.Controller, only: [get_flash: 2]

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PlatoWeb.Endpoint,
        router: PlatoWeb.Router,
        statics: ~w(assets fonts images favicon.ico robots.txt)
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
