defmodule SpotOnWeb.PageController do
  use SpotOnWeb, :controller
  require Logger

  def index(
        conn = %Plug.Conn{
          req_cookies: %{
            "spotify_access_token" => _,
            "spotify_refresh_token" => _
          }
        },
        _params
      ) do
    redirect(conn, to: "/users")
  end

  def index(conn = %Plug.Conn{}, _params) do
    redirect(conn, to: "/authorize?origin=/")
  end

  def home(conn = %Plug.Conn{}, _params) do
    user_name = conn |> get_session(:logged_in_user_name)
    redirect(conn, to: "/room/#{user_name}")
  end

  def logout(conn = %Plug.Conn{}, _params) do
    conn2 =
      conn
      |> clear_session
      |> delete_resp_cookie("spotify_access_token")
      |> delete_resp_cookie("spotify_refresh_token")
      |> delete_resp_cookie("_spot_on_web_key")

    redirect(conn2, external: "https://www.spotify.com/us/logout/")
  end

  def error(conn = %Plug.Conn{}, _params) do
    render(conn, "error.html")
  end
end
