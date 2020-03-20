defmodule SpotOnWeb.PageController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.Actions
  alias SpotOnWeb.Models.PageModel

  require Logger

  def index(conn = %Plug.Conn{}, credentials = %Credentials{}) do
    %ApiSuccess{credentials: new_credentials} = Api.refresh(credentials)

    new_conn = conn |> Cookies.set_cookies(new_credentials)
    render(new_conn, "index.html", build_index_data(new_conn))
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

  def build_index_data(conn = %Plug.Conn{}) do
    creds = conn |> Credentials.new

    user = Actions.get_my_user(creds)
    tracks = Actions.get_all_playing_tracks()
    users = Actions.get_all_users()
    follow_map = Actions.get_follow_map()

    %{page_model: PageModel.new(conn, user, users, tracks, follow_map)}
  end

end
