defmodule MstoskyWeb.AppLive.UserLiveHelpers do
  import Phoenix.Component
  alias Mstosky.Accounts.User
  alias Mstosky.Repo

  def handle_edit_user(socket, %{"id" => id}) do
    user = Enum.find(socket.assigns.filtered_users, fn u -> to_string(u.id) == to_string(id) end)

    if user do
      changeset =
        User.registration_changeset(user, %{}, validate_email: false, hash_password: false)

      {:noreply, assign(socket, edit_user_id: user.id, edit_user_changeset: changeset)}
    else
      {:noreply, socket}
    end
  end

  def handle_save_user_edit(socket, %{"user" => user_params}) do
    user_id = socket.assigns.edit_user_id
    user = Enum.find(socket.assigns.filtered_users, fn u -> u.id == user_id end)

    if user do
      changeset =
        User.registration_changeset(user, user_params,
          validate_email: false,
          hash_password: false
        )

      case Repo.update(changeset) do
        {:ok, updated_user} ->
          users =
            Enum.map(socket.assigns.users, fn u ->
              if u.id == user_id, do: updated_user, else: u
            end)

          filtered_users =
            Enum.map(socket.assigns.filtered_users, fn u ->
              if u.id == user_id, do: updated_user, else: u
            end)

          {:noreply,
           socket
           |> assign(
             users: users,
             filtered_users: filtered_users,
             edit_user_id: nil,
             edit_user_changeset: nil
           )
           |> Phoenix.LiveView.put_flash(:info, "User updated")}

        {:error, changeset} ->
          {:noreply, assign(socket, edit_user_changeset: changeset)}
      end
    else
      {:noreply, socket}
    end
  end

  def user_settings(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto bg-white dark:bg-gray-900 rounded-xl shadow p-8 mt-8">
      <h2 class="text-2xl font-bold mb-6 text-gray-800 dark:text-gray-100">Account Settings</h2>
      <%= if @current_user do %>
        <form phx-submit="update_settings" class="flex flex-col gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Email
            </label>
            <input
              type="text"
              value={@current_user.email}
              readonly
              class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 p-2.5"
            />
          </div>
          <div>
            <label
              for="display_name"
              class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1"
            >
              Display Name
            </label>
            <input
              id="display_name"
              name="display_name"
              type="text"
              value={@current_user.display_name}
              class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-gray-100 p-2.5 focus:ring-blue-600 focus:border-blue-600 dark:focus:ring-blue-500 dark:border-blue-500 transition"
            />
          </div>
          <button
            type="submit"
            class="w-full bg-blue-600 hover:bg-blue-700 dark:bg-blue-700 dark:hover:bg-blue-800 text-white font-semibold py-2.5 rounded-lg shadow-sm transition"
          >
            Save Changes
          </button>
        </form>
      <% else %>
        <p class="text-gray-500 dark:text-gray-400">You must be logged in to view settings.</p>
      <% end %>
    </div>
    """
  end
end
