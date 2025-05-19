defmodule MstoskyWeb.AppLive.FeedLiveHelpers do
  import Phoenix.Component
  alias Mstosky.FakePostQueue

  # Utility to filter posts by search string
  def filter_posts(posts, search) do
    posts
    |> Enum.filter(fn post ->
      String.contains?(String.downcase(post.content || ""), String.downcase(search))
    end)
  end

  def handle_filter_posts(socket, %{"post_search" => search}) do
    filtered = filter_posts(socket.assigns.posts, search)
    {:noreply, assign(socket, post_search: search, filtered_posts: filtered)}
  end

  def handle_generate_posts(socket, %{"value" => _}) do
    # Fallback for buttons that send only a value param, default to 5
    FakePostQueue.enqueue(5)
    {:noreply, assign(socket, fake_post_queue_processing: true)}
  end

  def handle_generate_posts(socket, %{"count" => count}) do
    n =
      case Integer.parse(count) do
        {val, _} when val > 0 -> val
        _ -> 5
      end

    FakePostQueue.enqueue(n)
    {:noreply, assign(socket, fake_post_queue_processing: true)}
  end

  def feed_section(assigns) do
    ~H"""
    <div class="bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-800 min-h-screen -mx-8 -mt-8 p-0">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="mb-8 text-center">
          <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-4">Your Unified Feed</h1>
          <p class="text-lg text-gray-600 dark:text-gray-300">
            Stay connected with your favorite content from Mastodon and Bluesky
          </p>
        </div>
        <%= if @current_user do %>
          <div class="mb-8 text-center">
            <button
              type="button"
              class="inline-block bg-blue-600 hover:bg-blue-700 dark:bg-blue-700 dark:hover:bg-blue-800 text-white px-6 py-2 rounded shadow transition font-semibold"
              phx-click="navigate"
              phx-value-page="new_post"
            >
              New Post
            </button>
          </div>
        <% end %>
        <div class="space-y-6">
          <%= for post <- @posts do %>
            <div class="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm flex items-start gap-4">
              <img
                src={post.avatar_url || "/images/default-avatar.png"}
                alt="Avatar"
                class="w-12 h-12 rounded-full object-cover border border-gray-200 dark:border-gray-700"
              />
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-2">
                  <span class="font-medium text-gray-900 dark:text-gray-100">
                    {(post.user && Map.get(post.user, :display_name)) ||
                      (post.user && Map.get(post.user, :email)) || "(no user)"}
                  </span>
                  <span class="ml-2 text-xs px-2 py-1 rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300">
                    {post.platform}
                  </span>
                </div>
                <p class="text-gray-800 dark:text-gray-200 mb-4">
                  {post.content}
                </p>
                <div class="flex items-center gap-6 text-gray-500 dark:text-gray-400">
                  <%= if @current_user do %>
                    <button class="hover:text-blue-600 dark:hover:text-blue-400 transition">
                      Like
                    </button>
                    <button class="hover:text-blue-600 dark:hover:text-blue-400 transition">
                      Repost
                    </button>
                  <% else %>
                    <span class="italic text-gray-400">Log in to like or repost</span>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
