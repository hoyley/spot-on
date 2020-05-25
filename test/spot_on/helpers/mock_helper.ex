defmodule SpotOn.Helpers.MockHelper do
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Profile
  import SpotOn.Helpers.Defaults

  defmacro __using__(_) do
    quote do
      @spotify_set_playing_song_delay_ms Application.get_env(
                                           :spot_on,
                                           :spotify_set_playing_song_delay_ms
                                         )

      import Mox
      use SpotOn.Helpers.Helper

      def mock_get_playing_track(playing_track = %PlayingTrack{}),
        do:
          mock_get_playing_track(
            playing_track,
            default_credentials()
          )

      def mock_get_playing_track(
            playing_track = %PlayingTrack{},
            credentials = %Credentials{}
          ),
          do: mock_get_playing_track(playing_track |> to_map, credentials)

      def mock_get_playing_track(playing_track, credentials = %Credentials{}) do
        ClientBehaviorMock
        |> expect(:get, fn creds, url ->
          assert url ===
                   "https://api.spotify.com/v1/me/player/currently-playing"

          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:ok, %HTTPoison.Response{status_code: 200, body: to_json(playing_track)}}
        end)
      end

      def mock_get_my_profile(credentials = %Credentials{}),
        do: mock_get_my_profile(default_my_profile(), credentials)

      def mock_get_my_profile(profile = %Profile{}, credentials = %Credentials{}) do
        ClientBehaviorMock
        |> expect(:get, fn creds, url ->
          assert url === "https://api.spotify.com/v1/me"

          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:ok, %HTTPoison.Response{status_code: 200, body: to_json(profile)}}
        end)
      end

      def mock_put_pause_track(credentials = %Credentials{}) do
        ClientBehaviorMock
        |> expect(:put, fn creds, url, _ ->
          assert url === "https://api.spotify.com/v1/me/player/pause"

          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
        end)
      end

      def mock_put_play_track(
            playing_track = %PlayingTrack{},
            credentials = %Credentials{}
          ) do
        ClientBehaviorMock
        |> expect(:put, fn creds, url, params ->
          {:ok, %{"uris" => [uri], "position_ms" => progress_ms}} = to_map(params)

          # Ensure the progress requested in the body is within a few milliseconds of what we expect.
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

      def mock_authenticate(),
        do: mock_authenticate(default_refresh_token(), default_access_token())

      def mock_authenticate(refresh_token, new_access_token) do
        ClientBehaviorMock
        |> expect(:authenticate, fn url, params ->
          assert url === "https://accounts.spotify.com/api/token"
          assert params == "grant_type=refresh_token&refresh_token=#{refresh_token}"

          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: '{"access_token": "#{new_access_token}", "refresh_token": "#{refresh_token}"}'
           }}
        end)
      end

      def mock_refresh_process(creds = %Credentials{}) do
        new_creds = Credentials.new("auth_after_refresh", creds.refresh_token)
        mock_authenticate(creds.refresh_token, new_creds.access_token)
        mock_get_my_profile(new_creds)
        new_creds
      end

      def mock_http_get_fail_401() do
        ClientBehaviorMock
        |> expect(:get, fn url, params ->
          {:ok, %HTTPoison.Response{status_code: 401}}
        end)
      end

      def mock_http_fail(credentials = %Credentials{}, client_action, reason) do
        ClientBehaviorMock
        |> expect(client_action, fn creds, url ->
          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:error, %HTTPoison.Error{reason: reason}}
        end)
      end

      def mock_http_fail_get_enetdown(credentials = %Credentials{}),
        do: mock_http_fail(credentials, :get, :enetdown)

      def mock_http_fail_get_nxdomain(credentials = %Credentials{}),
        do: mock_http_fail(credentials, :get, :nxdomain)

      def mock_http_fail_get_closed(credentials = %Credentials{}),
        do: mock_http_fail(credentials, :get, :closed)

      def mock_http_fail_get_connect_timeout(credentials = %Credentials{}),
        do: mock_http_fail(credentials, :get, :connect_timeout)

      def mock_http_fail_get_timeout(credentials = %Credentials{}),
        do: mock_http_fail(credentials, :get, :timeout)

      def mock_http_fail_get_refresh_revoked(credentials = %Credentials{}),
        do:
          ClientBehaviorMock
          |> expect(:get, fn creds, url ->
            assert creds.access_token === credentials.access_token
            assert creds.refresh_token === credentials.refresh_token

            {:error,
             %HTTPoison.Response{
               status_code: 400,
               body: ~s({"error":"invalid_grant","error_description":"Refresh token revoked"})
             }}
          end)
    end
  end
end
