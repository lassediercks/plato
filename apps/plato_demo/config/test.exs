import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :plato_demo, PlatoDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ESMz6NKTH+9WTyXikaKttpk3MQ9r6hPMPn2HZAWdJWE/3tF15Xi1k5v01cjT5Ec9",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
