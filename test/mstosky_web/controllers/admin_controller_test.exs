defmodule MstoskyWeb.AdminControllerTest do
  use MstoskyWeb.ConnCase, async: true
  import Phoenix.ConnTest

  alias Mstosky.Accounts

  @admin_email "admin@localhost"
  @admin_password "adminadminadmin"
  @user_email "user@localhost"
  @user_password "useruseruser"

  setup do
    # Create both an admin and a regular user
    {:ok, admin} =
      Accounts.register_user(%{
        email: @admin_email,
        password: @admin_password,
        admin: true
      })

    # Ensure admin is truly set in the DB
    admin = Ecto.Changeset.change(admin, admin: true) |> Mstosky.Repo.update!()

    {:ok, user} =
      Accounts.register_user(%{
        email: @user_email,
        password: @user_password,
        admin: false
      })

    %{admin: admin, user: user}
  end

  describe "admin access" do
    test "admin user can access admin dashboard", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      conn = get(conn, "/admin")
      assert html_response(conn, 200) =~ "Admin: Create a New Post"
    end

    test "non-admin user cannot access admin dashboard", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      conn = get(conn, "/admin")
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "You must be an admin to access this page."
    end

    test "unauthenticated user cannot access admin dashboard", %{conn: conn} do
      conn = get(conn, "/admin")
      assert redirected_to(conn) == "/users/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "You must log in to access this page."
    end
  end
end
