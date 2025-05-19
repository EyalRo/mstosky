defmodule Mstosky.Repo.Migrations.AddHandleToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :handle, :string
    end
  end
end
