defmodule SpotOn.Helpers.MockHelper do
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  import SpotOn.Helpers.Defaults

  defmacro __using__(_) do
    quote do

      @spotify_set_playing_song_delay_ms Application.get_env(:spot_on, :spotify_set_playing_song_delay_ms)

      import Mox
      use SpotOn.Helpers.Helper

      def mock_get_playing_track(playing_track = %PlayingTrack{}), do: mock_get_playing_track(playing_track,
        default_credentials())

      def mock_get_playing_track(playing_track = %PlayingTrack{}, credentials = %Credentials{}), do:
        mock_get_playing_track(playing_track |> to_map, credentials)

      def mock_get_playing_track(playing_track, credentials = %Credentials{}) do
        ClientBehaviorMock
        |> expect(:get, fn (creds, url) ->
          assert url === "https://api.spotify.com/v1/me/player/currently-playing"
          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:ok, %HTTPoison.Response{status_code: 200, body: to_json(playing_track)}}
        end)
      end

      def mock_put_pause_track(credentials = %Credentials{}) do
        ClientBehaviorMock
        |> expect(:put, fn (creds, url, _) ->
          assert url === "https://api.spotify.com/v1/me/player/pause"
          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
        end)
      end

      def mock_put_play_track(playing_track = %PlayingTrack{}, credentials = %Credentials{}) do
        ClientBehaviorMock
        |> expect(:put, fn (creds, url, params) ->
          {:ok, %{"uris" => [uri], "position_ms" => progress_ms}} = to_map(params)

          # Ensure the progress requested in the body is within 5 milliseconds of what we expect.
          # This isn't exact because it depends on code runtime
          expected_progress_ms = playing_track.progress_ms + @spotify_set_playing_song_delay_ms
          assert expected_progress_ms - 10 <= progress_ms
          assert expected_progress_ms + 10 >= progress_ms

          assert playing_track.track.song_uri === uri
          assert url === "https://api.spotify.com/v1/me/player/play"
          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
        end)
      end
    end
  end
end
