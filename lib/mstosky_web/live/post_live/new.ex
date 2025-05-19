defmodule MstoskyWeb.PostLive.New do
  use MstoskyWeb, :live_view
  alias Mstosky.Social
  alias Mstosky.Social.Post

  @impl true
  def mount(_params, session, socket) do
    current_user = Map.get(socket.assigns, :current_user) || Map.get(session, "current_user")
    socket = assign_new(socket, :current_user, fn -> current_user end)
    changeset = Post.changeset(%Post{}, %{})
    {:ok, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("create_post", %{"post" => post_params}, socket) do
    admin_user = socket.assigns.current_user

    attrs =
      Map.merge(post_params, %{
        "user_id" => admin_user.id,
        "avatar_url" => "/images/default-avatar.png",
        "platform" => "Mstosky"
      })

    case Social.create_post(attrs) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created!")
         |> push_navigate(to: "/feed")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <h1>New Post</h1>
    <.form :let={f} for={@changeset} as={:post} phx-submit="create_post">
      <.input field={f[:content]} placeholder="Content" />
      <button type="submit">Create Post</button>
    </.form>
    """
  end
end
