import Config

# Support DATABASE_URL for Docker, or individual config for local dev
database_url = System.get_env("DATABASE_URL")

# Start Plato.Repo when running standalone for development
config :plato, start_repo: true

config :plato, Plato.Repo, url: database_url
config :plato, ecto_repos: [Plato.Repo]

config :plato, PlatoWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT") || "4500")],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  secret_key_base:
    "a_very_long_secret_key_base_for_development_purposes_only_change_in_production",
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/plato_web/(controllers|components)/.*(ex|heex)$"
    ]
  ]
