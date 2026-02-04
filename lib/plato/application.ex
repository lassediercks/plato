defmodule Plato.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plato.Repo,
      PlatoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Plato.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
