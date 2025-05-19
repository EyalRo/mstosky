defmodule MstoskyWeb.UserRegistrationLive do
  use MstoskyWeb, :live_view

  alias Mstosky.Accounts
  alias Mstosky.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm mt-10 p-6 rounded-lg shadow bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800">
      <.header class="text-center text-zinc-900 dark:text-zinc-100">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        class="space-y-6"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input
          field={@form[:username]}
          type="text"
          label="Username"
          required
          class="bg-white dark:bg-zinc-800 border-zinc-300 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 dark:placeholder-zinc-500 focus:border-brand focus:ring-brand"
        />
        <.input
          field={@form[:email]}
          type="email"
          label="Email"
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
          <.button
            phx-disable-with="Creating account..."
            class="w-full bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 hover:bg-zinc-700 dark:hover:bg-zinc-200 border border-zinc-900 dark:border-zinc-100"
          >
            Create an account
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)
        token_b64 = Base.url_encode64(token, padding: false)
        {:noreply, push_event(socket, "session-login", %{user_token: token_b64})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
