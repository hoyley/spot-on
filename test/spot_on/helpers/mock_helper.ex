defmodule SpotOn.Helpers.MockHelper do
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack

  defmacro __using__(_) do
    quote do
      import Mox
      use SpotOn.Helpers.Helper

      def mock_get_playing_track(playing_track = %PlayingTrack{}), do: mock_get_playing_track(playing_track,
        Credentials.new("access", "token"))

      def mock_get_playing_track(playing_track = %PlayingTrack{}, credentials = %Credentials{}), do:
        mock_get_playing_track(playing_track |> to_map, credentials)

      def mock_get_playing_track(playing_track = %{}, credentials = %Credentials{}) do
        ClientBehaviorMock
        |> expect(:get, fn (creds, url) ->
          assert url === "https://api.spotify.com/v1/me/player/currently-playing"
          assert creds.access_token === credentials.access_token
          assert creds.refresh_token === credentials.refresh_token

          {:ok, %HTTPoison.Response{body: to_json(playing_track)}}
        end)
      end
    end
  end
end
