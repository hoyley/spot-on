defmodule SpotOn.SpotifyApi.Api do
  use SpotOn.SpotifyApi.ApiHelpers
  alias SpotOn.SpotifyApi.Player
  alias SpotOn.SpotifyApi.Profile
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Credentials

  def get_my_profile(conn = %Credentials{}) do
    conn
    |> call(&Profile.me/1)
  end

  def get_playing_track(user_id, credentials = %Credentials{}) do
    Logger.debug 'Fetching currently playing track from user [#{user_id}]'

    credentials
    |> call(&Player.current_track/1)
    |> case do
         success = %ApiSuccess{result: :ok} -> ApiSuccess.new(PlayingTrack.new(user_id), success.credentials)
         success = %ApiSuccess{result: track} -> ApiSuccess.new(PlayingTrack.new(user_id, track), success.credentials)
         failure = %ApiFailure{} ->
           Logger.error("#{failure.message}")
           ApiSuccess.new(PlayingTrack.new(user_id), failure.credentials)
       end
  end
end
