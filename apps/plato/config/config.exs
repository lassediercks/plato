import Config

# Configure the test repo when running tests
if Mix.env() == :test do
  # Get database config from environment or use defaults
  config :plato, Plato.Repo,
    username: System.get_env("POSTGRES_USER") || "postgres",
    password: System.get_env("POSTGRES_PASSWORD") || "postgres",
    hostname: System.get_env("POSTGRES_HOST") || "localhost",
    port: String.to_integer(System.get_env("POSTGRES_PORT") || "5433"),
    database: "plato_test#{System.get_env("MIX_TEST_PARTITION")}",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10

  config :plato,
    start_repo: true,
    ecto_repos: [Plato.Repo]

  config :logger, level: :warning
end
