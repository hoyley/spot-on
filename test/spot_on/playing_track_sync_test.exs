defmodule SpotOn.PlayingTrackSyncTest do
  alias SpotOn.Gen.PlayingTrackSync
  alias SpotOn.SpotifyApi.Track
  alias SpotOn.SpotifyApi.PlayingTrack

  import SpotOn.Helpers.Defaults
  import SpotOn.Helpers.ModelHelper

  use SpotOn.DataCase
  use SpotOn.Helpers.MockHelper

  setup [:set_mox_global]
  @playing_track_poll_ms Application.get_env(:spot_on, :playing_track_poll_ms)

  describe "syncing a users playing track" do

    setup do
      initial_track = default_playing_track()
      %{user: user, creds: creds} = create_user_and_tokens()
      mock_get_playing_track(default_playing_track(), creds)

      pid = PlayingTrackSync.start_link(user.name, creds)

      second_track =
        PlayingTrack.new(
          default_user_name(),
          1000,
          0,
          true,
          Track.new(
            "song_name",
            "song:uri",
            "artist_name1",
            "album_name",
            "url:image",
            120_000
          )
        )

      mock_get_playing_track(second_track, creds)

      {:ok,
       user: user, creds: creds, pid: pid, initial_track: initial_track, second_track: second_track}
    end

    test "can start sync", state do
      assert state[:pid] != nil
    end

    test "returns initial track correctly", state do
      assert_equals(
        state[:initial_track],
        PlayingTrackSync.get(state[:user].name)
      )
    end

    test "returns initial track correctly a second time", state do
      assert_equals(
        state[:initial_track],
        PlayingTrackSync.get(state[:user].name)
      )
    end

    test "can receive new song after poll", state do
      :timer.sleep(trunc(@playing_track_poll_ms * 1.1))

      assert_equals(
        state[:second_track],
        PlayingTrackSync.get(state[:user].name)
      )
    end

    test "can stop sync", state do
      PlayingTrackSync.stop_sync(state[:user].name)
    end
  end

  test "syncing a users playing track, error is handled gracefully" do
    %{user: user, creds: creds} = create_user_and_tokens()
    mock_get_playing_track(default_playing_track(), creds)

    PlayingTrackSync.start_link(user.name, creds)

    mock_http_fail_get_enetdown(creds)
    :timer.sleep(trunc(@playing_track_poll_ms * 1.1))

    assert PlayingTrackSync.get(default_user_name()) == nil
    end
end
