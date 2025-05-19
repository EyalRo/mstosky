defmodule MstoskyWeb.SessionController do
  use MstoskyWeb, :controller

  def create(conn, %{"user_token" => token_b64}) do
    case Base.url_decode64(token_b64, padding: false) do
      {:ok, user_token} ->
        conn
        |> put_session(:user_token, user_token)
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(:error, "Invalid session token")
        |> redirect(to: "/")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
