defmodule Mstosky.Repo.Migrations.AddFakeFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :fake, :boolean, default: false
      add :fake_source, :string
    end
  end
end
