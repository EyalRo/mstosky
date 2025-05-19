defmodule MstoskyWeb.PageControllerTest do
  use MstoskyWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    # Update this assertion to match your actual homepage content
    assert html_response(conn, 200) =~ "MstoSky"
  end
end
