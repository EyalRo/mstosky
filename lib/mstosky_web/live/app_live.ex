defmodule MstoskyWeb.AppLive do
  use MstoskyWeb, :live_view
  alias Mstosky.Accounts
  alias Mstosky.FakePostQueue

  import Phoenix.Controller, only: [get_csrf_token: 0]

  @impl true
  def mount(_params, session, socket) do
    # Persist debug_mode in session if present, fallback to false
    debug_mode = Map.get(session, "debug_mode", false)
    socket = assign_new(socket, :current_user, fn -> nil end)
    socket = assign_new(socket, :show_login, fn -> false end)
    socket = assign_new(socket, :page, fn -> :home end)

    socket = assign_new(socket, :posts, fn -> [] end)
    socket = assign_new(socket, :login_form, fn -> %{"email" => "", "password" => ""} end)
    socket = assign_new(socket, :login_error, fn -> nil end)
    socket = assign(socket, :csrf_token, get_csrf_token())
    socket = assign(socket, :debug_mode, debug_mode)
    socket = assign(socket, :edit_user_id, nil)
    socket = assign(socket, :edit_user_changeset, nil)
    {:ok, socket}
  end

  # TODO: For true persistence, store debug_mode in the session or user settings.

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @debug_mode do %>
      <div class="w-full bg-yellow-300 text-yellow-900 px-4 py-2 text-center font-semibold shadow-md z-50">
        Debug mode is ON
      </div>
    <% end %>
    <MstoskyWeb.NavComponents.navbar current_user={@current_user} csrf_token={@csrf_token} />

    <%= if @show_login do %>
      <div class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 dark:bg-opacity-70 z-50">
        <div class="bg-white dark:bg-gray-900 rounded-xl shadow-2xl p-8 w-full max-w-sm relative border border-gray-200 dark:border-gray-700">
          <button
            phx-click="hide_login"
            class="absolute top-2 right-2 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 text-2xl leading-none"
          >
            &times;
          </button>
          <h2 class="text-2xl font-bold mb-6 text-gray-800 dark:text-gray-100 text-center">
            Sign in to your account
          </h2>
          <form phx-submit="login" class="flex flex-col gap-4">
            <div>
              <label
                for="login"
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
              >
                Email or Username
              </label>
              <input id="login" name="user[email]" type="text" autocomplete="username" value={@login_form["email"]} class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-gray-100 p-2.5 focus:ring-blue-600 focus:border-blue-600 dark:focus:ring-blue-500 dark:focus:border-blue-500 transition" placeholder="you@example.com or username" required />
            </div>
            <div>
              <label
                for="password"
                class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
              >
                Password
              </label>
              <input id="password" name="user[password]" type="password" autocomplete="current-password" value={@login_form["password"]} class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-gray-100 p-2.5 focus:ring-blue-600 focus:border-blue-600 dark:focus:ring-blue-500 dark:focus:border-blue-500 transition" placeholder="••••••••" required />
            </div>
            <button
              type="submit"
              class="w-full bg-blue-600 hover:bg-blue-700 dark:bg-blue-700 dark:hover:bg-blue-800 text-white font-semibold py-2.5 rounded-lg shadow-sm transition"
            >
              Log in
            </button>
            <%= if @login_error do %>
              <span class="block text-center text-red-500 text-sm mt-2">{@login_error}</span>
            <% end %>
          </form>
        </div>
      </div>
    <% end %>
    <main class="p-8">
      <%= case @page do %>
        <% :new_post -> %>
          {MstoskyWeb.AppLive.PostLiveHelpers.new_post_form(assigns)}
        <% :home -> %>
          <div class="dark:bg-gray-900">
            <div class="bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-800 min-h-screen">
              <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-16 text-center">
                <h1 class="text-5xl font-bold text-gray-900 dark:text-gray-100 mb-8">MstoSky</h1>
                <p class="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto mb-12">
                  Discover and connect with your favorite content across Mastodon and Bluesky in one seamless experience.
                </p>
                <div class="flex justify-center gap-4 mb-16">
                  <button
                    phx-click="navigate"
                    phx-value-page="feed"
                    class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-green-600 dark:bg-green-500 hover:bg-green-700 dark:hover:bg-green-600 transition-colors"
                  >
                    View Your Feed
                  </button>
                </div>
              </div>

              <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 bg-white dark:bg-gray-900 rounded-t-3xl shadow-sm">
                <div class="text-center mb-12">
                  <h2 class="text-3xl font-bold text-gray-900 dark:text-gray-100">
                    Why Choose MstoSky?
                  </h2>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                  <div class="p-6 text-center">
                    <div class="w-12 h-12 mx-auto mb-4 flex items-center justify-center bg-blue-100 dark:bg-gray-800 rounded-full">
                      <svg
                        class="w-6 h-6 text-blue-600 dark:text-blue-300"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M13 10V3L4 14h7v7l9-11h-7z"
                        />
                      </svg>
                    </div>
                    <h3 class="text-xl font-semibold mb-2 text-gray-900 dark:text-gray-100">
                      Real-time Updates
                    </h3>
                    <p class="text-gray-600 dark:text-gray-300">
                      Stay connected with instant updates from both platforms in one unified feed.
                    </p>
                  </div>

                  <div class="p-6 text-center">
                    <div class="w-12 h-12 mx-auto mb-4 flex items-center justify-center bg-blue-100 dark:bg-gray-800 rounded-full">
                      <svg
                        class="w-6 h-6 text-blue-600 dark:text-blue-300"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                        />
                      </svg>
                    </div>
                    <h3 class="text-xl font-semibold mb-2 text-gray-900 dark:text-gray-100">
                      Cross-Platform Engagement
                    </h3>
                    <p class="text-gray-600 dark:text-gray-300">
                      Interact with both communities seamlessly from a single interface.
                    </p>
                  </div>

                  <div class="p-6 text-center">
                    <div class="w-12 h-12 mx-auto mb-4 flex items-center justify-center bg-blue-100 dark:bg-gray-800 rounded-full">
                      <svg
                        class="w-6 h-6 text-blue-600 dark:text-blue-300"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"
                        />
                      </svg>
                    </div>
                    <h3 class="text-xl font-semibold mb-2 text-gray-900 dark:text-gray-100">
                      Smart Customization
                    </h3>
                    <p class="text-gray-600 dark:text-gray-300">
                      Tailor your feed and notifications to match your interests perfectly.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% :feed -> %>
          {MstoskyWeb.AppLive.FeedLiveHelpers.feed_section(assigns)}
        <% :admin_dashboard -> %>
          <%= admin_layout(@current_user, :dashboard, fn -> %>
            {MstoskyWeb.AppLive.AdminLiveHelpers.admin_dashboard(assigns)}
          <% end) %>
        <% :admin_users -> %>
          <%= admin_layout(@current_user, :users, fn -> %>
            {MstoskyWeb.AppLive.AdminLiveHelpers.admin_users(assigns)}
          <% end) %>
        <% :admin_posts -> %>
          <%= admin_layout(@current_user, :posts, fn -> %>
            {MstoskyWeb.AppLive.AdminLiveHelpers.admin_posts(assigns)}
          <% end) %>
        <% :admin_settings -> %>
          <%= admin_layout(@current_user, :settings, fn -> %>
            {MstoskyWeb.AppLive.AdminLiveHelpers.admin_settings(assigns)}
          <% end) %>
        <% :admin_testing -> %>
          <%= admin_layout(@current_user, :testing, fn -> %>
            {MstoskyWeb.AppLive.AdminLiveHelpers.admin_testing(assigns)}
          <% end) %>
        <% :settings -> %>
          <%= MstoskyWeb.AppLive.UserLiveHelpers.user_settings(assigns) %>
        <% _ -> %>
          <p>Page not found.</p>
      <% end %>
    </main>
    """
  end

  # --- Admin Users State and Events ---
  defp filter_users(users, search, show_fake_users) do
    users
    |> Enum.filter(fn user ->
      (show_fake_users or !Map.get(user, :metadata, %{})["fake"]) &&
        (String.contains?(String.downcase(user.display_name || ""), String.downcase(search)) or
           String.contains?(String.downcase(user.email || ""), String.downcase(search)) or
           String.contains?(String.downcase(user.username || ""), String.downcase(search)))
    end)
  end

  # --- Admin Posts State and Events ---
  @impl true
  def handle_event("create_post", params, socket) do
    MstoskyWeb.AppLive.PostLiveHelpers.handle_create_post(socket, params)
  end

  @impl true
  def handle_event("edit_user", params, socket) do
    MstoskyWeb.AppLive.UserLiveHelpers.handle_edit_user(socket, params)
  end

  @impl true
  def handle_event("save_user_edit", params, socket) do
    MstoskyWeb.AppLive.UserLiveHelpers.handle_save_user_edit(socket, params)
  end

  @impl true
  def handle_event("close_user_edit_modal", _params, socket) do
    {:noreply, assign(socket, edit_user_id: nil, edit_user_changeset: nil)}
  end

  @impl true
  def handle_event("filter_users", %{"user_search" => search}, socket) do
    users = socket.assigns[:users] || []
    show_fake_users = socket.assigns[:show_fake_users] || false
    filtered = filter_users(users, search, show_fake_users)
    {:noreply, assign(socket, user_search: search, filtered_users: filtered)}
  end

  @impl true
  def handle_event("filter_posts", params, socket) do
    MstoskyWeb.AppLive.FeedLiveHelpers.handle_filter_posts(socket, params)
  end

  @impl true
  def handle_event("generate_posts", params, socket) do
    case params do
      %{"value" => _} ->
        MstoskyWeb.AppLive.AdminLiveHelpers.handle_generate_posts(socket, params)

      %{"count" => _} ->
        MstoskyWeb.AppLive.AdminLiveHelpers.handle_generate_posts(socket, params)

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_fake_users", params, socket) do
    MstoskyWeb.AppLive.AdminLiveHelpers.handle_toggle_fake_users(socket, params)
  end

  def handle_event("clear_done_jobs", params, socket) do
    MstoskyWeb.AppLive.AdminLiveHelpers.handle_clear_done_jobs(socket, params)
  end

  def handle_event("enqueue_fake_job", params, socket) do
    MstoskyWeb.AppLive.AdminLiveHelpers.handle_enqueue_fake_job(socket, params)
  end

  def handle_event("delete_user", params, socket) do
    MstoskyWeb.AppLive.AdminLiveHelpers.handle_delete_user(socket, params)
  end

  def handle_event("hide_login", _params, socket) do
    {:noreply, assign(socket, show_login: false, login_error: nil)}
  end

  def handle_event("login", %{"user" => %{"email" => email, "password" => password}}, socket) do
    case Accounts.get_user_by_email_or_username_and_password(email, password) do
      %Accounts.User{} = user ->
        token = Accounts.generate_user_session_token(user)
        token_b64 = Base.url_encode64(token, padding: false)
        {:noreply, push_event(socket, "session-login", %{user_token: token_b64})}

      _ ->
        {:noreply, assign(socket, login_error: "Invalid credentials", show_login: true)}
    end
  end

  def handle_event("logout", _params, socket) do
    # Clear user session and assign
    socket = assign(socket, current_user: nil)
    {:noreply, push_navigate(socket, to: "/", replace: true)}
  end

  def handle_event("update_settings", %{"display_name" => display_name}, socket) do
    current_user = socket.assigns.current_user
    updated_user = Map.put(current_user, :display_name, display_name)
    {:noreply, assign(socket, current_user: updated_user)}
  end

  def handle_event("toggle_debug", _params, socket) do
    debug_mode = !Map.get(socket.assigns, :debug_mode, false)
    # TODO: For true persistence, update session or user settings here
    debug_info =
      if debug_mode do
        %{
          ip_address: "127.0.0.1",
          uptime: "0h 0m",
          errors: 0,
          warnings: 0
        }
      else
        nil
      end

    {:noreply, assign(socket, debug_mode: debug_mode, debug_info: debug_info)}
  end

  def handle_event("delete_post", params, socket) do
    MstoskyWeb.AppLive.PostLiveHelpers.handle_delete_post(socket, params)
  end

  def handle_event("show_login", _params, socket) do
    {:noreply, assign(socket, show_login: true)}
  end

  def handle_event("navigate", %{"page" => page}, socket) do
    page_atom = String.to_existing_atom(page)

    socket =
      cond do
        page_atom == :admin_users ->
          users = Accounts.list_users()
          fake_users = Map.get(socket.assigns, :fake_users, [])
          user_search = Map.get(socket.assigns, :user_search, "")
          show_fake_users = Map.get(socket.assigns, :show_fake_users, false)
          filtered = filter_users(users ++ fake_users, user_search, show_fake_users)

          assign(socket,
            page: page_atom,
            users: users,
            fake_users: fake_users,
            user_search: user_search,
            show_fake_users: show_fake_users,
            filtered_users: filtered
          )

        page_atom == :admin_posts ->
          posts = Mstosky.Social.list_posts()
          assign(socket, page: page_atom, posts: posts, filtered_posts: posts)

        page_atom == :feed ->
          posts = Mstosky.Social.list_posts()
          assign(socket, page: page_atom, posts: posts)

        true ->
          assign(socket, page: page_atom)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:fake_post_queue, state}, socket) do
    {:noreply,
     assign(socket,
       fake_post_queue_processing: state.processing,
       fake_post_queue_pending: state.pending,
       fake_post_queue_jobs: state.jobs || []
     )}
  end

  def handle_info(:refresh_fake_post_queue, socket) do
    queue_state = FakePostQueue.state()

    {:noreply,
     assign(socket,
       fake_post_queue_processing: queue_state.processing,
       fake_post_queue_pending: queue_state.pending,
       fake_post_queue_jobs: queue_state.jobs || []
     )}
  end

  # Helper for shared admin layout
  defp admin_layout(current_user, active, inner_content) do
    assigns = %{current_user: current_user, active: active, inner_content: inner_content}

    ~H"""
    <%= if @current_user && @current_user.admin do %>
      <div class="bg-gray-50 dark:bg-gray-900 min-h-screen">
        <div class="grid grid-cols-1 md:grid-cols-[220px_1fr] gap-8">
          <!-- Sidebar -->
          <aside class="col-span-1 h-full bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 rounded-lg p-6">
            <nav class="space-y-4">
              <button
                phx-click="navigate"
                phx-value-page="admin_dashboard"
                class={"block w-full text-left px-3 py-2 rounded font-semibold transition " <> if @active == :dashboard, do: "text-blue-700 dark:text-blue-300 bg-blue-100 dark:bg-gray-900 font-bold", else: "text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400"}
              >
                Dashboard
              </button>
              <button
                phx-click="navigate"
                phx-value-page="admin_users"
                class={"block w-full text-left px-3 py-2 rounded font-semibold transition " <> if @active == :users, do: "text-blue-700 dark:text-blue-300 bg-blue-100 dark:bg-gray-900 font-bold", else: "text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400"}
              >
                Users
              </button>
              <button
                phx-click="navigate"
                phx-value-page="admin_posts"
                class={"block w-full text-left px-3 py-2 rounded font-semibold transition " <> if @active == :posts, do: "text-blue-700 dark:text-blue-300 bg-blue-100 dark:bg-gray-900 font-bold", else: "text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400"}
              >
                Posts
              </button>
              <button
                phx-click="navigate"
                phx-value-page="admin_settings"
                class={"block w-full text-left px-3 py-2 rounded font-semibold transition " <> if @active == :settings, do: "text-blue-700 dark:text-blue-300 bg-blue-100 dark:bg-gray-900 font-bold", else: "text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400"}
              >
                Settings
              </button>
              <button
                phx-click="navigate"
                phx-value-page="admin_testing"
                class={"block w-full text-left px-3 py-2 rounded font-semibold transition " <> if @active == :testing, do: "text-blue-700 dark:text-blue-300 bg-blue-100 dark:bg-gray-900 font-bold", else: "text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400"}
              >
                Testing
              </button>
            </nav>
          </aside>
          <!-- Main content -->
          <section class="col-span-1">
            {@inner_content.()}
          </section>
        </div>
      </div>
    <% else %>
      <p class="text-red-600">You must be an admin to view this page.</p>
    <% end %>
    """
  end
end
