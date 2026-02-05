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

    base_path = opts[:base_path] || "/"

    # Store otp_app and base_path in conn assigns for controllers and templates to use
    conn
    |> Plug.Conn.assign(:plato_otp_app, otp_app)
    |> Plug.Conn.assign(:plato_base_path, base_path)
    |> PlatoWeb.Router.call(PlatoWeb.Router.init([]))
  end
end
