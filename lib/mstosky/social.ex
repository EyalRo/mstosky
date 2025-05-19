defmodule Mstosky.Social do
  @moduledoc """
  The Social context for managing posts.
  """
  import Ecto.Query, warn: false
  alias Mstosky.Repo
  alias Mstosky.Social.Post

  @doc """
  Returns the list of posts ordered by newest first.
  """
  def list_posts do
    Repo.all(from p in Post, order_by: [desc: p.inserted_at]) |> Repo.preload(:user)
  end

  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def delete_post(id) do
    post = Repo.get!(Post, id)
    Repo.delete(post)
  end

  @doc """
  Search posts by content, author, or platform (case-insensitive, partial match).
  """
  def search_posts(query) when is_binary(query) and query != "" do
    pattern = "%" <> query <> "%"

    Repo.all(
      from p in Post,
        where:
          ilike(p.content, ^pattern) or ilike(p.author, ^pattern) or ilike(p.platform, ^pattern),
        order_by: [desc: p.inserted_at]
    )
    |> Repo.preload(:user)
  end

  def search_posts(_), do: list_posts()

  def generate_fake_posts(n) do
    for _i <- 1..n do
      IO.puts("[generate_fake_posts] Job started at #{DateTime.utc_now()} (job #")
      user = create_fake_user()

      if user do
        IO.puts(
          "[generate_fake_posts] Using user: #{user.id} (#{user.email}) [fake=#{inspect(user.fake)}]"
        )

        IO.inspect(user, label: "[generate_fake_posts] User details")

        attrs = %{
          author: user.display_name || user.username || user.email,
          handle: user.username,
          avatar_url: user.avatar_url,
          content: "This is a generated post.",
          platform: "fake",
          user_id: user.id
        }

        case create_post(attrs) do
          {:ok, post} ->
            IO.puts("[generate_fake_posts] Post created for user #{user.id}")
            IO.inspect(post, label: "[generate_fake_posts] Post details")

          other ->
            IO.puts(
              "[generate_fake_posts] Failed to create post for user #{user.id}: #{inspect(other)}"
            )
        end
      else
        IO.puts("[generate_fake_posts] Failed to create or fetch user!")
      end

      :ok
    end
  end

  defp debug? do
    Application.get_env(:mstosky, :debug, false)
  end

  defp create_fake_user do
    alias Mstosky.Accounts
    alias Faker.{Internet, Person, Lorem}

    # Ensure Faker is started (safe to call multiple times)
    Application.ensure_all_started(:faker)
    fake_email = Internet.email()
    fake_username = Internet.user_name()
    fake_display_name = Person.name()

    fake_avatar_url =
      "https://api.dicebear.com/7.x/bottts/svg?seed=#{Lorem.characters(8) |> Enum.join()}"

    fake_password = Lorem.characters(12) |> Enum.join()

    attrs = %{
      "fake" => true,
      "fake_source" => "faker",
      "metadata" => %{"fake" => true, "source" => "faker"},
      "password" => fake_password,
      "provider" => nil,
      "provider_uid" => nil,
      "email" => fake_email,
      "username" => fake_username,
      "display_name" => fake_display_name,
      "avatar_url" => fake_avatar_url
    }

    # Convert relevant keys to atoms for Ecto
    atom_attrs =
      attrs
      |> Enum.map(fn {k, v} ->
        case k do
          "fake" -> {:fake, v}
          "fake_source" -> {:fake_source, v}
          "email" -> {:email, v}
          "username" -> {:username, v}
          "display_name" -> {:display_name, v}
          "avatar_url" -> {:avatar_url, v}
          "password" -> {:password, v}
          "provider" -> {:provider, v}
          "provider_uid" -> {:provider_uid, v}
          _ -> {String.to_atom(k), v}
        end
      end)
      |> Enum.into(%{})

    if debug?(), do: IO.puts("[create_fake_user] attrs: #{inspect(attrs)}")
    if debug?(), do: IO.puts("[create_fake_user] atom_attrs: #{inspect(atom_attrs)}")

    result =
      try do
        Accounts.register_user(atom_attrs)
      rescue
        e ->
          if debug?(),
            do: IO.puts("[create_fake_user] Exception during register_user: #{inspect(e)}")

          nil
      end

    if debug?(), do: IO.puts("[create_fake_user] register_user result: #{inspect(result)}")

    cond do
      _match = match?({:ok, %_{}}, result) ->
        {:ok, user} = result
        if debug?(), do: IO.puts("[create_fake_user] Success: #{inspect(user)}")
        user

      _match = match?({:error, _}, result) ->
        if debug?(),
          do:
            IO.puts(
              "[create_fake_user] Registration error, trying get_or_create_external_user..."
            )

        fallback = Accounts.User.get_or_create_external_user(attrs)

        if debug?(),
          do:
            IO.puts(
              "[create_fake_user] get_or_create_external_user fallback: #{inspect(fallback)}"
            )

        if fallback,
          do: fallback,
          else:
            (
              if debug?(), do: IO.puts("[create_fake_user] get_user_by_email fallback...")
              Accounts.get_user_by_email(attrs["email"])
            )

      is_nil(result) ->
        if debug?(),
          do:
            IO.puts(
              "[create_fake_user] register_user returned nil, trying get_or_create_external_user..."
            )

        fallback = Accounts.User.get_or_create_external_user(attrs)

        if debug?(),
          do:
            IO.puts(
              "[create_fake_user] get_or_create_external_user fallback: #{inspect(fallback)}"
            )

        if fallback,
          do: fallback,
          else:
            (
              if debug?(), do: IO.puts("[create_fake_user] get_user_by_email fallback...")
              Accounts.get_user_by_email(attrs["email"])
            )

      true ->
        if debug?(), do: IO.puts("[create_fake_user] All user creation attempts failed.")
        nil
    end
  end
end
