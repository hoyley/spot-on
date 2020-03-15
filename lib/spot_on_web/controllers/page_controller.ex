defmodule SpotOnWeb.PageController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.Actions

  def index(conn = %Plug.Conn{}, credentials = %Credentials{}) do
    %ApiSuccess{credentials: new_credentials} = Actions.get_my_profile(credentials)
    new_conn = conn |> Cookies.set_cookies(new_credentials)
    render(new_conn, "index.html", build_index_data(new_credentials))
  end

  def index(conn = %Plug.Conn{req_cookies: %{"spotify_access_token" => _, "spotify_refresh_token" => _}}, _params) do
    index(conn, Credentials.new(conn))
  end

  def index(conn = %Plug.Conn{}, _params) do
    redirect conn, to: "/authorize"
  end

  def logout(conn = %Plug.Conn{}, _params) do
    conn2 = conn |> clear_session
      |> delete_resp_cookie("spotify_access_token")
      |> delete_resp_cookie("spotify_refresh_token")
      |> delete_resp_cookie("_spot_on_web_key")

      redirect conn2, external: "https://www.spotify.com/us/logout/"
  end

  def build_index_data(conn = %Credentials{}) do
    %ApiSuccess{result: profile} = Actions.get_my_profile(conn)
    tracks = Actions.get_all_users_playing_tracks();

    %{logged_in_user_name: profile.display_name, tracks: tracks}
  end

end
