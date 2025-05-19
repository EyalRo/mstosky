defmodule Mstosky.Repo do
  use Ecto.Repo,
    otp_app: :mstosky,
    adapter: Ecto.Adapters.SQLite3
end
