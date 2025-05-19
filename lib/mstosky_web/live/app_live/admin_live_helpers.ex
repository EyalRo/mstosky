defmodule MstoskyWeb.AppLive.AdminLiveHelpers do
  import Phoenix.Component
  alias Mstosky.FakePostQueue

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

  # Admin/moderation event handlers
  def handle_toggle_fake_users(socket, _params) do
    show_fake = !socket.assigns.show_fake_users
    users = socket.assigns.users ++ socket.assigns.fake_users
    filtered = filter_users(users, socket.assigns.user_search, show_fake)
    {:noreply, assign(socket, show_fake_users: show_fake, filtered_users: filtered)}
  end

  def handle_clear_done_jobs(socket, _params) do
    FakePostQueue.clear_done_jobs()
    {:noreply, socket}
  end

  def handle_enqueue_fake_job(socket, _params) do
    FakePostQueue.enqueue_fake_debug_job()
    {:noreply, socket}
  end

  def handle_delete_user(socket, %{"id" => id}) do
    current_user = socket.assigns.current_user

    user_id =
      case id do
        i when is_integer(i) -> i
        i when is_binary(i) -> String.to_integer(i)
      end

    if current_user && current_user.id == user_id do
      # Do nothing if trying to delete self
      {:noreply, socket}
    else
      Mstosky.Accounts.delete_user(user_id)
      users = Enum.reject(socket.assigns.users, fn u -> u.id == user_id end)
      fake_users = Enum.reject(socket.assigns.fake_users, fn u -> u.id == user_id end)

      filtered =
        filter_users(
          users ++ fake_users,
          socket.assigns.user_search,
          socket.assigns.show_fake_users
        )

      {:noreply,
       assign(socket,
         users: users,
         fake_users: fake_users,
         filtered_users: filtered,
         edit_user_id: nil,
         edit_user_changeset: nil
       )}
    end
  end

  # Utility for filtering users
  def filter_users(users, search, show_fake_users) do
    users
    |> Enum.filter(fn user ->
      (show_fake_users or !Map.get(user, :metadata, %{})["fake"]) &&
        (String.contains?(String.downcase(user.display_name || ""), String.downcase(search)) or
           String.contains?(String.downcase(user.email || ""), String.downcase(search)) or
           String.contains?(String.downcase(user.username || ""), String.downcase(search)))
    end)
  end

  def admin_dashboard(assigns) do
    ~H"""
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold text-blue-700 dark:text-blue-300">Dashboard</h1>
    </div>
    <section class="mt-24">
      <h2 class="text-xl font-bold text-blue-800 dark:text-blue-200 mb-4 flex items-center gap-2">
        <svg class="h-6 w-6 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 8v4l3 3m6 0a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        Job Queue
      </h2>
      <div class="p-4 rounded-lg shadow border border-blue-200 dark:border-blue-700 bg-blue-50 dark:bg-blue-900">
        <div class="flex items-center gap-4 mb-4">
          <span class="font-semibold text-blue-900 dark:text-blue-100">Background Task Queue</span>
          <span class="ml-auto text-xs px-2 py-1 rounded bg-blue-200 text-blue-800 dark:bg-blue-800 dark:text-blue-200">
            {if Map.get(assigns, :fake_post_queue_processing, false), do: "Processing", else: "Idle"}
          </span>
        </div>
        <div class="overflow-x-auto">
          <div class="flex gap-4">
            <%= if is_list(Map.get(assigns, :fake_post_queue_jobs, [])) and Enum.any?(Map.get(assigns, :fake_post_queue_jobs, [])) do %>
              <%= for job <- Map.get(assigns, :fake_post_queue_jobs, []) do %>
                <div class={"min-w-[180px] p-4 rounded-lg shadow flex flex-col items-start gap-2 " <>
                  case job.status do
                    :processing -> "bg-blue-200 dark:bg-blue-700 border border-blue-400 dark:border-blue-500"
                    :queued -> "bg-blue-100 dark:bg-blue-900 border border-blue-200 dark:border-blue-700"
                    :done -> "bg-green-100 dark:bg-green-900 border border-green-400 dark:border-green-700"
                  end}>
                  <span class={"text-xs font-semibold px-2 py-1 rounded " <>
                    case job.status do
                      :processing -> "bg-blue-400 text-white"
                      :queued -> "bg-blue-200 text-blue-800 dark:bg-blue-800 dark:text-blue-200"
                      :done -> "bg-green-500 text-white"
                    end}>
                    {job.status |> to_string() |> String.capitalize()}
                  </span>
                  <span class="text-xs text-blue-700 dark:text-blue-200">
                    <%= case job.type do %>
                      <% :generate_post -> %>
                        Generate Post
                      <% :fake -> %>
                        Fake Job
                      <% _ -> %>
                        {to_string(job.type)}
                    <% end %>
                  </span>
                  <span class="text-xs text-gray-700 dark:text-gray-300">
                    <%= case job.status do %>
                      <% :processing -> %>
                        Processing for {job.duration}s
                      <% :queued -> %>
                        Queued for {job.duration}s
                      <% _ -> %>
                    <% end %>
                  </span>
                  <%= if job.status == :done do %>
                    <span class="text-xs text-green-700 dark:text-green-300">
                      Done in {Map.get(job, :processing_duration, job.duration)}s
                    </span>
                    <%= if Map.has_key?(job, :result) do %>
                      <span class={"text-xs font-bold ml-2 " <>
                        case job.result do
                          :ok -> "text-green-700 dark:text-green-300"
                          {:error, _} -> "text-red-700 dark:text-red-400"
                          _ -> "text-gray-600 dark:text-gray-300"
                        end}>
                        {case job.result do
                          :ok -> "Success"
                          {:error, _} -> "Failure"
                          _ -> inspect(job.result)
                        end}
                      </span>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            <% else %>
              <div class="text-xs text-blue-400 italic">No queued operations.</div>
            <% end %>
          </div>
        </div>
      </div>
    </section>
    """
  end

  def admin_settings(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">Settings</h1>
    </div>
    <div class="flex flex-col gap-6">
      <div class="w-full bg-yellow-50 dark:bg-yellow-900 rounded-lg shadow border border-yellow-200 dark:border-yellow-700 p-6 flex flex-col sm:flex-row items-center justify-between">
        <div class="flex flex-col items-start w-full sm:w-auto">
          <h2 class="text-lg font-semibold text-yellow-800 dark:text-yellow-200 mb-2">Debug Mode</h2>
          <form phx-submit="toggle_debug" class="flex items-center gap-2">
            <button
              type="submit"
              class="relative inline-flex h-6 w-11 items-center rounded-full focus:outline-none border border-yellow-400 dark:border-yellow-700 bg-yellow-200 dark:bg-yellow-800"
            >
              <span class={"inline-block h-4 w-4 transform rounded-full bg-yellow-500 transition " <> if Map.get(assigns, :debug_mode, false), do: "translate-x-6", else: "translate-x-1"}>
              </span>
            </button>
          </form>
        </div>
        <span class="ml-0 sm:ml-auto mt-4 sm:mt-0 text-xs px-2 py-1 rounded bg-yellow-200 text-yellow-800 dark:bg-yellow-800 dark:text-yellow-200 font-semibold">
          {if Map.get(assigns, :debug_mode, false), do: "ON", else: "OFF"}
        </span>
      </div>
    </div>
    """
  end

  def admin_testing(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">Testing</h1>
    </div>
    <div class="mb-8 flex flex-col sm:flex-row gap-2 sm:gap-4 items-center w-full sm:w-auto">
      <button
        class="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded text-xs font-semibold transition"
        phx-click="enqueue_fake_job"
      >
        Enqueue Fake Job
      </button>
      <button
        class="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded text-xs font-semibold transition"
        phx-click="generate_posts"
      >
        Generate Posts
      </button>
    </div>
    """
  end

  def admin_posts(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">Posts</h1>
    </div>
    <div class="mb-8 flex flex-col sm:flex-row gap-2 sm:gap-4 items-center w-full sm:w-auto">
      <form phx-change="filter_posts" class="w-full sm:w-auto flex-1">
        <input
          type="text"
          phx-debounce="300"
          name="post_search"
          value={Map.get(assigns, :post_search, "")}
          placeholder="Search posts..."
          class="w-full sm:w-64 px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-blue-600 focus:border-blue-600 dark:focus:ring-blue-500 dark:border-blue-500 transition"
        />
      </form>
    </div>
    <div class="space-y-4">
      <%= for post <- Map.get(assigns, :filtered_posts, @posts) do %>
        <div class="flex items-center gap-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700">
          <img
            src={post.avatar_url || "/images/default-avatar.png"}
            alt="avatar"
            class="w-12 h-12 rounded-full border border-gray-300 dark:border-gray-700 object-cover"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="font-semibold text-gray-900 dark:text-gray-100 truncate">
                {(post.user && Map.get(post.user, :display_name)) ||
                  (post.user && Map.get(post.user, :email)) || "(no user)"}
              </span>
              <span class="ml-2 text-xs px-2 py-1 rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300">
                {post.platform}
              </span>
            </div>
            <div class="text-gray-600 dark:text-gray-300 text-sm truncate">{post.content}</div>
          </div>
          <div class="flex flex-col gap-2 sm:flex-row sm:gap-2 ml-auto">
            <button
              class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-1 rounded text-xs font-semibold transition"
              phx-click="edit_post"
              phx-value-id={post.id}
            >
              Edit
            </button>
            <button
              class="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded text-xs font-semibold transition"
              phx-click="delete_post"
              phx-value-id={post.id}
            >
              Delete
            </button>
          </div>
        </div>
      <% end %>
      <%= if Enum.empty?(Map.get(assigns, :filtered_posts, @posts)) do %>
        <div class="text-center text-gray-400 py-12">No posts found.</div>
      <% end %>
    </div>
    """
  end

  def admin_users(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">Users</h1>
    </div>
    <div class="mb-8 flex flex-col sm:flex-row gap-2 sm:gap-4 items-center w-full sm:w-auto">
      <form phx-change="filter_users" class="w-full sm:w-auto flex-1">
        <input
          type="text"
          phx-debounce="300"
          name="user_search"
          value={Map.get(assigns, :user_search, "")}
          placeholder="Search users..."
          class="w-full sm:w-64 px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-blue-600 focus:border-blue-600 dark:focus:ring-blue-500 dark:border-blue-500 transition"
        />
      </form>
      <label class="flex items-center gap-2 cursor-pointer select-none mb-0">
        <input
          type="checkbox"
          phx-click="toggle_fake_users"
          checked={Map.get(assigns, :show_fake_users, false)}
          class="form-checkbox h-5 w-5 text-blue-600 transition"
        />
        <span class="text-gray-700 dark:text-gray-200 text-sm">Display fake users</span>
      </label>
    </div>
    <div class="space-y-4">
      <%= for user <- Map.get(assigns, :filtered_users, []) do %>
        <div class="flex items-center gap-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700">
          <img
            src={user.avatar_url || "/images/default-avatar.png"}
            alt="avatar"
            class="w-12 h-12 rounded-full border border-gray-300 dark:border-gray-700 object-cover"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="font-semibold text-gray-900 dark:text-gray-100 truncate">
                {user.display_name || user.email}
              </span>
              <%= if user.admin do %>
                <span class="ml-2 text-xs px-2 py-1 rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300">
                  admin
                </span>
              <% end %>
              <%= if (Map.get(user, :fake, false) or Map.get(user, :metadata, %{})["fake"]) do %>
                <span class="ml-2 text-xs px-2 py-1 rounded font-bold uppercase bg-yellow-300 dark:bg-yellow-800 text-yellow-900 dark:text-yellow-200 border border-yellow-500">
                  Fake User
                </span>
              <% end %>
            </div>
            <div class="text-gray-600 dark:text-gray-300 text-sm truncate">{user.email}</div>
            <div class="text-gray-400 dark:text-gray-400 text-xs">{user.username}</div>
          </div>
        </div>
      <% end %>
      <%= if Enum.empty?(Map.get(assigns, :filtered_users, [])) do %>
        <div class="text-center text-gray-400 py-12">No users found.</div>
      <% end %>
    </div>
    """
  end
end
