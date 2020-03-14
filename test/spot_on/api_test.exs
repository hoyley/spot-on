defmodule SpotOn.ApiTest do
  import Mox
  alias SpotOn.Actions
  alias SpotOn.Model
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Track
  use SpotOnWeb.ConnCase
  use SpotOn.Helper

  describe "api" do

    test "when get playing track" do
      playing_track = PlayingTrack.new("username", 1000, 0, Track.new("song_name", "artist_name", "album_name"))

      playing_track
      |> test_playing_track
    end

    test "when get playing track with multiple artists" do
      base_track = PlayingTrack.new("username", 1000, 0, Track.new("song_name", "artist_name1", "album_name"))
      expected_track = PlayingTrack.new("username", 1000, 0, Track.new("song_name", "artist_name1, artist_name2", "album_name"))

      base_track
      |> to_map
      |> add_artist("artist_name2")
      |> test_playing_track(expected_track)
    end

    def test_playing_track(track = %PlayingTrack{}), do: test_playing_track(track |> to_map, track)

    def test_playing_track(track_api_response = %{}, expected_track = %PlayingTrack{}) do
      user = Model.create_user(expected_track.user_name)
      Model.create_user_tokens(%{user_id: user.id, access_token: "access", refresh_token: "refresh"})

      ClientBehaviorMock
      |> expect(:get, fn (creds, url) ->
        assert url === "https://api.spotify.com/v1/me/player/currently-playing"
        assert creds.access_token === "access"
        assert creds.refresh_token === "refresh"

        {:ok, %HTTPoison.Response{body: to_json(track_api_response)}}
      end)

      Actions.get_playing_track(user)
      |> assert_equals(expected_track)
    end
  end
end
