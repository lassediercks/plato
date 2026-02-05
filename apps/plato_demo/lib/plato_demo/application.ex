defmodule PlatoDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PlatoDemo.Repo,
      PlatoDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:plato_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PlatoDemo.PubSub},
      # Start a worker by calling: PlatoDemo.Worker.start_link(arg)
      # {PlatoDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      PlatoDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PlatoDemo.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Sync CMS schemas after supervisor starts
    Plato.sync_schemas(PlatoDemo.ContentSchemas, otp_app: :plato_demo)

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PlatoDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
