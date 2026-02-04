import Config

config :plato, ecto_repos: [Plato.Repo]

config :phoenix, :json_library, Jason

env_config = Path.join([__DIR__, "#{config_env()}.exs"])

if File.exists?(env_config) do
  import_config env_config
end
