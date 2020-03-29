defmodule SpotOnWeb.PageController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.Actions

  require Logger

  def index(conn = %Plug.Conn{}, credentials = %Credentials{}) do
    %ApiSuccess{credentials: new_credentials} = Api.refresh(credentials)

    new_conn =
      conn
      |> Cookies.set_cookies(new_credentials)
      |> put_session(
        "logged_in_user_name",
        Actions.get_my_user(new_credentials).name
      )
      |> put_session("spotify_access_token", new_credentials.access_token)
      |> put_session("spotify_refresh_token", new_credentials.refresh_token)

    redirect(new_conn, to: "/users")
  end

  def index(
        conn = %Plug.Conn{
          req_cookies: %{
            "spotify_access_token" => _,
            "spotify_refresh_token" => _
          }
        },
        _params
      ) do
    index(conn, Credentials.new(conn))
  end

  def index(conn = %Plug.Conn{}, _params) do
    redirect(conn, to: "/authorize")
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
end
