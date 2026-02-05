# Start the test repo
{:ok, _} = Application.ensure_all_started(:plato)

# Set the repo to sandbox mode
Ecto.Adapters.SQL.Sandbox.mode(Plato.Repo, :manual)

ExUnit.start()
