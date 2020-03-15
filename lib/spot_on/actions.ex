defmodule SpotOn.Actions do
  alias SpotOn.Model
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  require Logger

  def get_my_profile(conn = %Credentials{}) do
    Api.get_my_profile(conn)
  end

  def get_credentials_by_user_id(user_id) do
    Model.get_user_token_by_user_name(user_id)
    |> Credentials.new
  end

  def get_all_users_playing_tracks() do
    Model.list_spotify_users()
      |> (Enum.map fn user ->
        get_playing_track(user.name)
      end) || []
  end

  def get_playing_track(user_id) when is_binary(user_id) do
    SpotOn.Gen.PlayingTrackApi.get(user_id)
    || PlayingTrack.new(user_id)
  end

end
