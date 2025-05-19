defmodule Mstosky.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :status, :string, default: "active", null: false
      add :role, :string, default: "user", null: false
      add :joined_at, :utc_datetime
      add :last_active_at, :utc_datetime
      add :email_confirmed, :boolean, default: false
      add :language, :string, default: "en"
      add :theme_pref, :string, default: "system"
      add :bio, :text
    end
  end
end
