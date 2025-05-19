defmodule Mstosky.Repo.Migrations.AddProviderUidUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:provider, :provider_uid])
  end
end
