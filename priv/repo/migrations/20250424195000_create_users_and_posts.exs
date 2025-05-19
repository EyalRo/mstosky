defmodule Mstosky.Repo.Migrations.CreateUsersAndPosts do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :username, :string, null: false
      add :display_name, :string
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :admin, :boolean, default: false
      add :provider, :string
      add :provider_uid, :string
      add :avatar_url, :string
      add :external, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:posts) do
      add :content, :text, null: false
      add :author, :string
      add :user_id, references(:users, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:user_id])
  end
end
