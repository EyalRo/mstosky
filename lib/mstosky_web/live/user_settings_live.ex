defmodule MstoskyWeb.UserSettingsLive do
  use MstoskyWeb, :live_view

  alias Mstosky.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address, display name, and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@username_form}
          id="username_form"
          phx-submit="update_username"
          phx-change="validate_username"
        >
          <.input field={@username_form[:username]} type="text" label="Username" required />
          <:actions>
            <.button phx-disable-with="Saving...">Save Username</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@display_name_form}
          id="display_name_form"
          phx-submit="update_display_name"
          phx-change="validate_display_name"
        >
          <.input field={@display_name_form[:display_name]} type="text" label="Display Name" />
          <:actions>
            <.button phx-disable-with="Saving...">Save Display Name</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input
            field={@email_form[:email]}
            type="email"
            label="Email"
            value={@current_user.email}
            required
          />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_user.email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]

    if user do
      email_changeset = Accounts.change_user_email(user)
      password_changeset = Accounts.change_user_password(user)
      display_name_changeset = Ecto.Changeset.change(user, %{})
      username_changeset = Ecto.Changeset.change(user, %{})

      socket =
        socket
        |> assign(:email_form, to_form(email_changeset))
        |> assign(:password_form, to_form(password_changeset))
        |> assign(:display_name_form, to_form(display_name_changeset))
        |> assign(:username_form, to_form(username_changeset))
        |> assign(:display_name_form_current, user.display_name)
        |> assign(:email_form_current_password, "")
        |> assign(:trigger_submit, false)

      {:ok, socket}
    else
      {:halt, socket}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("validate_display_name", params, socket) do
    user_params = params["user"] || %{}
    atom_params = for {k, v} <- user_params, into: %{}, do: {String.to_existing_atom(k), v}

    changeset =
      socket.assigns.current_user
      |> Ecto.Changeset.change(atom_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, display_name_form: to_form(changeset))}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("update_display_name", %{"user" => params}, socket) do
    user = socket.assigns.current_user
    atom_params = for {k, v} <- params, into: %{}, do: {String.to_atom(k), v}
    changeset = Ecto.Changeset.change(user, atom_params)

    case Mstosky.Repo.update(changeset) do
      {:ok, updated_user} ->
        # Update all posts with the old display name or email as author
        import Ecto.Query

        Mstosky.Repo.update_all(
          from(p in Mstosky.Social.Post,
            where: p.author == ^updated_user.display_name or p.author == ^updated_user.email
          ),
          set: [author: updated_user.display_name]
        )

        {:noreply,
         socket
         |> put_flash(:info, "Display name updated!")
         |> assign(display_name_form: to_form(Ecto.Changeset.change(updated_user, %{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, display_name_form: to_form(changeset))}
    end
  end

  def handle_event("update_username", %{"user" => params}, socket) do
    user = socket.assigns.current_user
    atom_params = for {k, v} <- params, into: %{}, do: {String.to_atom(k), v}

    changeset =
      user
      |> Ecto.Changeset.change(atom_params)
      |> Ecto.Changeset.cast(atom_params, [:username])
      |> Ecto.Changeset.validate_required([:username])
      |> Ecto.Changeset.validate_length(:username, min: 3, max: 32)
      |> Ecto.Changeset.unsafe_validate_unique(:username, Mstosky.Repo)
      |> Ecto.Changeset.unique_constraint(:username)

    case Mstosky.Repo.update(changeset) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(current_user: updated_user)
         |> assign(username_form: to_form(Ecto.Changeset.change(updated_user, %{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, username_form: to_form(changeset))}
    end
  end

  def handle_event("validate_username", %{"user" => params}, socket) do
    user = socket.assigns.current_user
    atom_params = for {k, v} <- params, into: %{}, do: {String.to_atom(k), v}

    changeset =
      user
      |> Ecto.Changeset.change(atom_params)
      |> Ecto.Changeset.cast(atom_params, [:username])
      |> Ecto.Changeset.validate_required([:username])
      |> Ecto.Changeset.validate_length(:username, min: 3, max: 32)
      |> Ecto.Changeset.unsafe_validate_unique(:username, Mstosky.Repo)
      |> Ecto.Changeset.unique_constraint(:username)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, username_form: to_form(changeset))}
  end
end
