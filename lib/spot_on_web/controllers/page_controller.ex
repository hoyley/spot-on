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

  def follow(conn = %Plug.Conn{}, params) when is_map(params) do
    follow(conn, params["leader"])
  end

  def follow(conn = %Plug.Conn{}, leader_name) do
    Actions.start_follow(conn |> Credentials.new, leader_name)
    redirect conn, to: "/"
  end

  def unfollow(conn = %Plug.Conn{}, params) do
    unfollow(conn, params["leader"], params["follower"])
  end

  def unfollow(conn = %Plug.Conn{}, leader_name, follower_name) do
    Actions.stop_follow(leader_name, follower_name)
    redirect conn, to: "/"
  end

  def build_index_data(conn = %Credentials{}) do
    %ApiSuccess{result: profile} = Actions.get_my_profile(conn)
    tracks = Actions.get_all_users_playing_tracks()
    follow_map = Actions.get_follow_map()

    %{logged_in_user_name: profile.display_name, tracks: tracks, follow_map: follow_map}
  end

end
