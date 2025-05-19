defmodule MstoskyWeb.UserSessionController do
  use MstoskyWeb, :controller

  def create(conn, %{"user_token" => user_token}) do
    user_token = Base.url_decode64!(user_token, padding: false)

    conn
    |> put_session(:user_token, user_token)
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end
end
