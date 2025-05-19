defmodule MstoskyWeb.UserLoginLive do
  use MstoskyWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm mt-10 p-6 rounded-lg shadow bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800">
      <.header class="text-center text-zinc-900 dark:text-zinc-100">
        Log in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" phx-submit="login" class="space-y-6">
        <.input
          field={@form[:email]}
          type="text"
          label="Username or Email"
          required
          class="bg-white dark:bg-zinc-800 border-zinc-300 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 dark:placeholder-zinc-500 focus:border-brand focus:ring-brand"
        />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          required
          class="bg-white dark:bg-zinc-800 border-zinc-300 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 dark:placeholder-zinc-500 focus:border-brand focus:ring-brand"
        />

        <:actions>
          <.input
            field={@form[:remember_me]}
            type="checkbox"
            label="Keep me logged in"
            class="dark:checked:bg-zinc-700"
          />
          <.link
            href={~p"/users/reset_password"}
            class="text-sm font-semibold text-brand hover:underline"
          >
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button
            phx-disable-with="Logging in..."
            class="w-full bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 hover:bg-zinc-700 dark:hover:bg-zinc-200 border border-zinc-900 dark:border-zinc-100"
          >
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  def handle_event("login", %{"user" => %{"email" => login, "password" => password}}, socket) do
    case Mstosky.Accounts.get_user_by_email_or_username_and_password(login, password) do
      %Mstosky.Accounts.User{} = user ->
        user_token = Mstosky.Accounts.generate_user_session_token(user)
        user_token = Base.url_encode64(user_token, padding: false)
        {:noreply, push_navigate(socket, to: "/users/log_in/session?user_token=#{user_token}")}

      _ ->
        {:noreply,
         Phoenix.LiveView.put_flash(socket, :error, "Invalid username/email or password")}
    end
  end

  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> Phoenix.LiveView.put_flash(:info, "Logged out successfully.")
     |> Phoenix.LiveView.redirect(to: "/")
     |> assign(:current_user, nil)}
  end
end
