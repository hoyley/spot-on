defmodule SpotOn.SpotifyApi.Api do
  use SpotOn.SpotifyApi.ApiHelpers
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Player
  alias SpotOn.SpotifyApi.Profile
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Credentials

  def get_my_profile(conn = %Credentials{}) do
    conn
    |> call(&Profile.me/1)
  end

  def play_track(credentials = %Credentials{}, song_uri, position_ms) do
    params =
      %{uris: [song_uri], position_ms: position_ms}
      |> Poison.encode!()

    function = fn creds -> Player.play(creds, params) end

    credentials
    |> call(function)
  end

  def pause_track(credentials = %Credentials{}) do
    credentials
    |> call(&Player.pause/1)
  end

  def get_playing_track(user_id, credentials = %Credentials{}) do
    Logger.debug('Fetching currently playing track from user [#{user_id}]')

    credentials
    |> call(&Player.current_track/1)
    |> case do
      success = %ApiSuccess{result: nil} ->
        ApiSuccess.new(success.credentials)

      success = %ApiSuccess{result: track} ->
        ApiSuccess.new(success.credentials, PlayingTrack.new(user_id, track))

      failure = %ApiFailure{} ->
        Logger.error("#{failure.message}")
        failure
    end
  end
end
