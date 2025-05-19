defmodule MstoskyWeb.NavComponents do
  use Phoenix.Component

  def navbar(assigns) do
    assigns = assign_new(assigns, :current_user, fn -> nil end)

    ~H"""
    <nav class="bg-white dark:bg-gray-800 shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center">
            <div class="flex-shrink-0 flex items-center">
              <button
                phx-click="navigate"
                phx-value-page="home"
                class="text-xl font-bold text-blue-600 dark:text-blue-400 bg-transparent border-none cursor-pointer"
              >
                MstoSky
              </button>
            </div>
            <div class="ml-10 flex items-center space-x-4">
              <button
                phx-click="navigate"
                phx-value-page="feed"
                class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 bg-transparent border-none cursor-pointer"
              >
                Feed
              </button>
              <%= if @current_user && @current_user.admin do %>
                <button
                  phx-click="navigate"
                  phx-value-page="admin_dashboard"
                  class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 bg-transparent border-none cursor-pointer"
                >
                  Admin
                </button>
              <% end %>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <button
              id="theme-toggle"
              class="p-2 rounded-lg bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
              aria-label="Toggle theme"
            >
              <svg
                class="w-6 h-6 hidden dark:block text-yellow-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707"
                />
              </svg>
              <svg
                class="w-6 h-6 dark:hidden text-gray-700"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
                />
              </svg>
            </button>
            <%= if @current_user do %>
              <div class="flex items-center space-x-2">
                <button
                  phx-click="navigate"
                  phx-value-page="settings"
                  class="flex items-center space-x-2 group bg-transparent border-none cursor-pointer p-0"
                >
                  <img
                    class="h-8 w-8 rounded-full bg-gray-200 border border-gray-300 dark:border-gray-700 object-cover group-hover:ring-2 group-hover:ring-blue-400"
                    src={
                      @current_user.avatar_url ||
                        "https://api.dicebear.com/7.x/initials/svg?seed=#{URI.encode(@current_user.display_name || @current_user.username || @current_user.email)}&backgroundType=gradientLinear&backgroundColor=F3F4F6,1E293B"
                    }
                    alt="User avatar"
                    referrerpolicy="no-referrer"
                  />
                  <span class="text-sm text-gray-700 dark:text-gray-300 group-hover:text-blue-600 dark:group-hover:text-blue-400">
                    {@current_user.username || @current_user.email}
                  </span>
                </button>
                <form action="/session" method="post" style="display:inline;">
                  <input type="hidden" name="_method" value="delete" />
                  <input type="hidden" name="_csrf_token" value={@csrf_token || ""} />
                  <button
                    type="submit"
                    class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-red-600 dark:hover:text-red-400 bg-transparent border-none cursor-pointer"
                  >
                    Log out
                  </button>
                </form>
              </div>
            <% else %>
              <a
                href="/users/register"
                class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400"
              >
                Register
              </a>
              <button
                phx-click="show_login"
                class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 bg-transparent border-none cursor-pointer"
              >
                Log in
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </nav>
    """
  end
end
