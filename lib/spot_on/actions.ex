defmodule SpotOn.Actions do
  alias SpotOn.Model
  alias SpotOn.Model.User
  alias SpotOn.Model.UserTokens
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.Credentials
  require Logger

  def get_my_profile(conn = %Credentials{}) do
    Api.get_my_profile(conn)
  end

  def get_all_users_playing_tracks() do
    Model.list_spotify_users()
      |> (Enum.map fn user ->
        get_playing_track(user)
      end) || []
  end

  def get_playing_track(user = %User{}), do: get_playing_track(user, Model.get_user_token(user))
  def get_playing_track(user = %User{}, tokens = %UserTokens{}), do:
    get_playing_track(user.name, tokens |> Credentials.new)

  def get_playing_track(user_id, credentials = %Credentials{}) do
    SpotOn.Gen.PlayingTrack.start_link(user_id, credentials)
    SpotOn.Gen.PlayingTrack.get(user_id)
  end

end
