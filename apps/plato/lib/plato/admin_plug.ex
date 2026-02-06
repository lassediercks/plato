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

    # Calculate the full base path by combining script_name (outer scopes)
    # with the path from opts (the plato_admin path)
    base_path = compute_base_path(conn, opts[:base_path] || "/")

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

  # Compute the full base path including outer scopes
  defp compute_base_path(conn, relative_path) do
    # script_name contains the path segments consumed by outer scopes
    script_name = Enum.join(conn.script_name, "/")

    # Combine script_name with the relative path
    case {script_name, relative_path} do
      {"", path} -> path
      {script, "/"} -> "/#{script}"
      {script, path} -> "/#{script}#{path}"
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
