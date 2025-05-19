defmodule Mstosky.Repo.Migrations.AddAvatarUrlToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :avatar_url, :string
    end
  end
end
