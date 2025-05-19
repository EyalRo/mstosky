defmodule Mstosky.Repo.Migrations.AddPlatformToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :platform, :string
    end
  end
end
