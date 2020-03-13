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
      
      user = Model.create_user(playing_track.user_name)
      Model.create_user_tokens(%{user_id: user.id, access_token: "access", refresh_token: "refresh"})

      ClientBehaviorMock
      |> expect(:get, fn (creds, url) ->
        assert url === "https://api.spotify.com/v1/me/player/currently-playing"
        assert creds.access_token === "access"
        assert creds.refresh_token === "refresh"

        {:ok, %HTTPoison.Response{body: to_json(playing_track)}}
      end)

      Actions.get_playing_track(user)
      |> assert_equals(playing_track)
    end
  end
end
