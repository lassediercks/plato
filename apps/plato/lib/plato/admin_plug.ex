defmodule Plato.AdminPlug do
  @moduledoc false
  # Internal plug that forwards requests to the admin router with configuration

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, opts) do
    otp_app =
      opts[:otp_app] ||
        raise ArgumentError, """
        Must provide :otp_app to plato_admin.

        Example:
            plato_admin "/admin/cms", otp_app: :my_app
        """

    # Calculate the full base path from script_name
    # script_name contains all consumed path segments including the plato_admin path
    base_path = compute_base_path(conn)

    # Serve static assets first
    conn = serve_static(conn)

    # If static asset was served, return early
    if conn.halted do
      conn
    else
      # Store otp_app and base_path in conn assigns for controllers and templates to use
      conn
      |> Plug.Conn.assign(:plato_otp_app, otp_app)
      |> Plug.Conn.assign(:plato_base_path, base_path)
      |> PlatoWeb.Router.call(PlatoWeb.Router.init([]))
    end
  end

  # Compute the full base path from script_name
  # script_name contains all path segments consumed by scopes (e.g., ["dev", "cms"])
  defp compute_base_path(conn) do
    case conn.script_name do
      [] -> "/"
      segments -> "/" <> Enum.join(segments, "/")
    end
  end

  # Serve static assets from Plato's priv/static directory
  defp serve_static(conn) do
    opts =
      Plug.Static.init(
        at: "/",
        from: :plato,
        gzip: false,
        only: ~w(css fonts images favicon.ico robots.txt)
      )

    Plug.Static.call(conn, opts)
  end
end
