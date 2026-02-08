defmodule PlatoWeb.TestEndpoint do
  @moduledoc false
  # Test endpoint that uses the TestRouter for proper admin path mounting

  use Phoenix.Endpoint, otp_app: :plato

  # Configure error rendering - must come before other plugs
  plug Phoenix.CodeReloader

  @session_options [
    store: :cookie,
    key: "_plato_test_key",
    signing_salt: "test_signing_salt",
    same_site: "Lax"
  ]

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(PlatoWeb.TestRouter)
end
