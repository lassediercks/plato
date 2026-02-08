# Start the test repo
{:ok, _} = Application.ensure_all_started(:plato)

# Start the test endpoint for controller tests
{:ok, _} = PlatoWeb.TestEndpoint.start_link()

# Set the repo to sandbox mode
Ecto.Adapters.SQL.Sandbox.mode(Plato.Repo, :manual)

ExUnit.start()
