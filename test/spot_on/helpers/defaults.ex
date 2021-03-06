defmodule SpotOn.Helpers.Defaults do
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Track
  alias SpotOn.SpotifyApi.Profile

  def default_user_name, do: "test_user"
  def default_user_display_name, do: "Test User"
  def default_access_token, do: "access"
  def default_refresh_token, do: "refresh"

  def default_credentials,
    do: Credentials.new(default_access_token(), default_refresh_token())

  def default_playing_track_song_name, do: "Song2"
  def default_playing_track_song_uri, do: "spotify:track:3423423"
  def default_playing_track_artist_name, do: "Artist"
  def default_playing_track_album_name, do: "Album"
  def default_playing_track_small_image, do: "http://test.com/image"
  def default_playing_track_duration_ms, do: 120_000
  def default_playing_progress_ms, do: 5000

  def default_playing_track,
    do:
      PlayingTrack.new(
        default_user_name(),
        default_playing_progress_ms(),
        1_231_231,
        true,
        Track.new(
          default_playing_track_song_name(),
          default_playing_track_song_uri(),
          default_playing_track_artist_name(),
          default_playing_track_album_name(),
          default_playing_track_small_image(),
          default_playing_track_duration_ms()
        )
      )

  def default_my_profile,
    do: %Profile{id: default_user_name(), display_name: default_user_display_name()}
end
