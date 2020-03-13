defmodule SpotOnWeb.PageController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.Credentials

  def index(conn = %Plug.Conn{}, credentials = %Credentials{}) do
    Api.update_tokens(credentials)
    render_logged_in(conn)
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

  def render_logged_in(conn = %Plug.Conn{}) do
    data = %{tracks: SpotOn.Actions.get_all_users_playing_tracks()}
    render(conn, "index.html", data)
  end

end
