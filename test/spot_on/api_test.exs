defmodule SpotOn.ApiTest do
  import Mox
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Track
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.ApiFailure
  use SpotOnWeb.ConnCase
  use SpotOn.Helpers.MockHelper
  import SpotOn.Helpers.ModelHelper

  describe "api" do
    test "get playing track" do
      playing_track =
        PlayingTrack.new(
          "username",
          1000,
          0,
          true,
          Track.new(
            "song_name",
            "song:uri",
            "artist_name",
            "album_name",
            "url:image",
            1000
          )
        )

      playing_track
      |> test_playing_track
    end

    test "get playing track with multiple artists" do
      base_track =
        PlayingTrack.new(
          "username",
          1000,
          0,
          true,
          Track.new(
            "song_name",
            "song:uri",
            "artist_name1",
            "album_name",
            "url:image",
            1000
          )
        )

      expected_track =
        PlayingTrack.new(
          "username",
          1000,
          0,
          true,
          Track.new(
            "song_name",
            "song:uri",
            "artist_name1, artist_name2",
            "album_name",
            "url:image",
            1000
          )
        )

      base_track
      |> to_map
      |> add_artist("artist_name2")
      |> test_playing_track(expected_track)
    end

    def test_playing_track(track = %PlayingTrack{}),
      do: test_playing_track(track |> to_map, track)

    def test_playing_track(
          track_api_response = %{},
          expected_track = %PlayingTrack{}
        ) do
      %{user: user, creds: creds} = create_user_and_tokens(expected_track.user_name)

      mock_get_playing_track(track_api_response, creds)

      success = Api.get_playing_track(user.name, creds)
      success.result |> assert_equals(expected_track)
    end

    test "http get call failure retries successfully on token expired" do
      %{creds: creds} = create_user_and_tokens()

      mock_http_get_fail_401()
      new_creds = mock_refresh_process(creds)
      mock_get_my_profile(new_creds)

      success = %ApiSuccess{} = Api.get_my_profile(new_creds)
      assert new_creds == success.credentials
    end

    test "http get call failure when internet down" do
      %{creds: creds} = create_user_and_tokens()

      mock_http_fail_get_enetdown(creds)

      failure = %ApiFailure{} = Api.get_my_profile(creds)
      assert failure.status === :enet_down
    end

    test "http get call failure when unreachable" do
      %{creds: creds} = create_user_and_tokens()

      mock_http_fail_get_nxdomain(creds)

      failure = %ApiFailure{} = Api.get_my_profile(creds)
      assert failure.status === :unreachable
    end

    test "http get call failure when closed" do
      %{creds: creds} = create_user_and_tokens()

      mock_http_fail_get_closed(creds)

      failure = %ApiFailure{} = Api.get_my_profile(creds)
      assert failure.status === :connection_closed
    end

    test "http get call failure when connect timeout" do
      %{creds: creds} = create_user_and_tokens()

      mock_http_fail_get_connect_timeout(creds)

      failure = %ApiFailure{} = Api.get_my_profile(creds)
      assert failure.status === :timeout
    end

    test "http get call failure when timeout" do
      %{creds: creds} = create_user_and_tokens()

      mock_http_fail_get_timeout(creds)

      failure = %ApiFailure{} = Api.get_my_profile(creds)
      assert failure.status === :timeout
    end
  end
end
