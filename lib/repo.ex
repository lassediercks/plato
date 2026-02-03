defmodule Plato.Repo do
  use Ecto.Repo,
    otp_app: :plato,
    adapter: Ecto.Adapters.Postgres
end
