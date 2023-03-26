defmodule NotSpotify.Repo do
  use Ecto.Repo,
    otp_app: :not_spotify,
    adapter: Ecto.Adapters.Postgres
end
