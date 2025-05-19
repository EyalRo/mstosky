defmodule Mstosky.Social.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :author, :string
    field :handle, :string
    field :avatar_url, :string
    field :content, :string
    field :platform, :string
    belongs_to :user, Mstosky.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:author, :handle, :avatar_url, :content, :platform, :user_id])
    |> validate_required([:author, :handle, :content, :platform])
  end
end
