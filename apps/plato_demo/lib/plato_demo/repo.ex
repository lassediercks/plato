defmodule PlatoDemo.Repo do
  use Ecto.Repo,
    otp_app: :plato_demo,
    adapter: Ecto.Adapters.Postgres
end
