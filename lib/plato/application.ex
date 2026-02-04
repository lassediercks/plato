defmodule Plato.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Only start Plato.Repo and Endpoint when running Plato standalone for development
    # When used as a library, these should not be started
    children =
      if Application.get_env(:plato, :start_repo, false) do
        [Plato.Repo, PlatoWeb.Endpoint]
      else
        []
      end

    opts = [strategy: :one_for_one, name: Plato.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
