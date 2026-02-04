defmodule PlatoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :plato

  @session_options [
    store: :cookie,
    key: "_plato_key",
    signing_salt: "plato_signing_salt",
    same_site: "Lax"
  ]

  # Code reloading can be explicitly enabled under the :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.Static,
    at: "/",
    from: :plato,
    gzip: false,
    only: ~w(css fonts images favicon.ico robots.txt)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug PlatoWeb.Router
end
