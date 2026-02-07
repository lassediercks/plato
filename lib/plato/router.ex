defmodule Plato.Router do
  @moduledoc """
  Router for mounting the Plato admin interface.

  ## Usage

  In your app's router:

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import Plato.Router

        scope "/" do
          pipe_through :browser
          plato_admin "/admin/cms", otp_app: :my_app
        end
      end

  This will mount the admin UI at `/admin/cms` (or any custom path you choose).

  ## Configuration

  The admin will automatically use your app's configured repo:

      config :my_app, :plato,
        repo: MyApp.Repo

  ## Custom Paths

  The path is completely configurable - mount at any location:

      plato_admin "/cms", otp_app: :my_app
      plato_admin "/admin/content", otp_app: :my_app
      plato_admin "/backstage", otp_app: :my_app
  """

  @doc """
  Mounts the Plato admin interface at the given path.

  ## Options

    * `:otp_app` - The OTP app to read config from (required)

  ## Examples

      plato_admin "/admin/cms", otp_app: :my_app
      plato_admin "/cms", otp_app: :my_app
  """
  defmacro plato_admin(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      scope path, alias: false, as: false do
        # Forward all requests to the Plato admin plug
        # Pass the mount path through opts so AdminPlug can use it
        forward("/", Plato.AdminPlug, Keyword.put(opts, :base_path, path))
      end
    end
  end
end
