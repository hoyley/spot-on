defmodule SpotOn.Actions do
  alias SpotOn.Model
  alias SpotOn.Model.UserTokens
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.Player
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.Profile
  alias SpotOn.Model.User

  def get_my_profile(conn = %Plug.Conn{}) do
    conn |> Api.call(&Profile.me/1)
  end

  def get_all_users_playing_tracks() do
    Model.list_spotify_users()
      |> (Enum.map fn token ->
        get_playing_track(token)
      end) || []
  end

  def get_playing_track(user = %User{}), do: get_playing_track(user, Model.get_user_token(user))

  def get_playing_track(user = %User{}, tokens = %UserTokens{}) do
    tokens
    |> Credentials.new()
    |> Api.call(&Player.current_track/1)
    |> case do
         :ok -> PlayingTrack.new(user.name)
         {:ok, track} -> PlayingTrack.new(user.name, track)
         failure = %ApiFailure{} ->
           IO.puts("#{failure.message}")
           PlayingTrack.new(user.name)
       end
  end
end
