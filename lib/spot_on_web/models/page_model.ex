defmodule SpotOnWeb.Models.PageModel do
  alias SpotOnWeb.Models.PageModel
  alias SpotOn.Model.User
  alias SpotOn.SpotifyApi.PlayingTrack

  defstruct ~w[ conn logged_in_user users follow_map playing_tracks]a

  def new(conn = %Plug.Conn{}, logged_in_user = %User{}, users, playing_tracks, follow_map)
      when is_map(follow_map) when is_list(users) when is_list(playing_tracks) do
    %PageModel{ conn: conn, logged_in_user: logged_in_user, users: users, playing_tracks: playing_tracks,
      follow_map: follow_map }
  end
end
