defmodule MstoskyWeb.AppLive.PostLiveHelpers do
  import Phoenix.Component
  alias Mstosky.Social

  def handle_create_post(socket, %{"content" => content}) do
    current_user = socket.assigns.current_user

    attrs = %{
      "content" => content,
      "user_id" => current_user && current_user.id,
      "platform" => "local",
      "author" =>
        (current_user &&
           (current_user.display_name || current_user.username || current_user.email)) ||
          "Anonymous",
      "handle" => (current_user && current_user.username) || nil,
      "avatar_url" => (current_user && current_user.avatar_url) || ""
    }

    case Social.create_post(attrs) do
      {:ok, _post} ->
        posts = Social.list_posts()
        {:noreply, assign(socket, posts: posts, page: :feed)}

      {:error, changeset} ->
        debug_mode = Map.get(socket.assigns, :debug_mode, false)

        debug_info =
          if debug_mode do
            errors =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                Enum.reduce(opts, msg, fn {key, value}, acc ->
                  String.replace(acc, "%{#{key}}", to_string(value))
                end)
              end)

            inspect(errors)
          else
            nil
          end

        flash_msg =
          if debug_info, do: "Could not create post: #{debug_info}", else: "Could not create post"

        {:noreply, Phoenix.LiveView.put_flash(socket, :error, flash_msg)}
    end
  end

  def handle_delete_post(socket, %{"id" => id}) do
    id = String.to_integer(id)
    Social.delete_post(id)
    posts = Social.list_posts()
    {:noreply, assign(socket, posts: posts, filtered_posts: posts)}
  end

  def new_post_form(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto bg-white dark:bg-gray-900 rounded-xl shadow p-8 mt-8">
      <h2 class="text-2xl font-bold mb-6 text-gray-800 dark:text-gray-100">Create New Post</h2>
      <form phx-submit="create_post" class="flex flex-col gap-4">
        <textarea
          name="content"
          class="w-full rounded border border-gray-300 dark:border-gray-700 p-2 min-h-[100px]"
          placeholder="What's on your mind?"
          required
        ></textarea>
        <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded">
          Post
        </button>
      </form>
    </div>
    """
  end
end
