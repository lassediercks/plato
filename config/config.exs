import Config

# Configure PlatoWeb.Endpoint error rendering
config :plato, PlatoWeb.Endpoint,
  render_errors: [
    formats: [html: PlatoWeb.ErrorHTML],
    layout: false
  ]

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

  # Configure test endpoint
  config :plato, PlatoWeb.TestEndpoint,
    http: [port: 4002],
    server: false,
    secret_key_base: String.duplicate("a", 64),
    render_errors: [
      formats: [html: PlatoWeb.ErrorHTML],
      layout: false
    ]

  # Configure test storage with dummy credentials
  # This is for testing purposes only - use environment variables in production
  config :plato,
    storage: [
      adapter: Plato.Storage.S3Adapter,
      bucket: "plato-test-bucket",
      access_key_id: "test-access-key",
      secret_access_key: "test-secret-key",
      region: "us-east-1"
    ]

  # Configure ExAws to use mock HTTP client in tests
  config :ex_aws,
    http_client: Plato.MockHTTPClient,
    json_codec: Jason

  config :logger, level: :warning
end
