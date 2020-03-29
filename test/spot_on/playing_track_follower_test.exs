defmodule SpotOn.PlayingTrackFollowerTest do
  alias SpotOn.Gen.FollowerSupervisor
  alias SpotOn.Gen.PlayingTrackSync
  alias SpotOn.SpotifyApi.Credentials

  import SpotOn.Helpers.ModelHelper

  use SpotOn.DataCase
  use SpotOn.Helpers.MockHelper

  setup [:set_mox_global]

  @progress_threshold Application.get_env(:spot_on, :follower_threshold_ms)
  @leader_name "leader"
  @follower_name "follower"
  @leader_creds Credentials.new("leader_access", "leader_refresh")
  @follower_creds Credentials.new("follower_access", "follower_refresh")

  test "when leader is inactive and follower is inactive, do nothing" do
    run_test(nil, nil)
  end

  test "when leader is paused and follower is inactive, do nothing" do
    run_test(new_paused_track(@leader_name), nil)
  end

  test "when leader is inactive and follower is paused, do nothing" do
    run_test(nil, new_paused_track(@follower_name))
  end

  test "when leader is inactive and follower is playing, do nothing" do
    run_test(nil, new_playing_track(@follower_name))
  end

  test "when leader is paused and follower is paused, do nothing" do
    run_test(new_paused_track(@leader_name), new_paused_track(@follower_name))
  end

  test "when leader is paused and follower is playing, should pause track" do
    mock_put_pause_track(@follower_creds)
    run_test(new_paused_track(@leader_name), new_playing_track(@follower_name))
  end

  test "when leader is playing and follower is playing a different song, should sync" do
    leader_track = new_playing_track(@leader_name)

    follower_track = new_playing_track(%{user_name: @follower_name, song_uri: "wrong song"})

    mock_put_play_track(leader_track, @follower_creds)
    run_test(leader_track, follower_track)
  end

  test "when leader is playing and follower is playing the same song but too far ahead, should sync" do
    leader_track = new_playing_track(@leader_name)
    follower_progress = leader_track.progress_ms + @progress_threshold + 5

    follower_track =
      new_playing_track(%{
        user_name: @follower_name,
        progress_ms: follower_progress
      })

    mock_put_play_track(leader_track, @follower_creds)
    run_test(leader_track, follower_track)
  end

  test "when leader is playing and follower is playing the same song but too far behind, should sync" do
    leader_track = new_playing_track(@leader_name)
    follower_progress = leader_track.progress_ms - @progress_threshold - 5

    follower_track =
      new_playing_track(%{
        user_name: @follower_name,
        progress_ms: follower_progress
      })

    mock_put_play_track(leader_track, @follower_creds)
    run_test(leader_track, follower_track)
  end

  test "when leader is playing and follower is playing the same but ahead within threshold, do nothing" do
    leader_track = new_playing_track(@leader_name)
    follower_progress = leader_track.progress_ms + @progress_threshold - 5

    follower_track =
      new_playing_track(%{
        user_name: @follower_name,
        progress_ms: follower_progress
      })

    run_test(leader_track, follower_track)
  end

  test "when leader is playing and follower is playing the same but behind within threshold, do nothing" do
    leader_track = new_playing_track(@leader_name)
    follower_progress = leader_track.progress_ms - @progress_threshold + 5

    follower_track =
      new_playing_track(%{
        user_name: @follower_name,
        progress_ms: follower_progress
      })

    run_test(leader_track, follower_track)
  end

  def run_test(leader_track, follower_track) do
    supervisor_pid = FollowerSupervisor.start_link()

    %{user: _leader, creds: _} = create_user_and_tokens(@leader_name, @leader_creds)

    %{user: _follower, creds: _} = create_user_and_tokens(@follower_name, @follower_creds)

    mock_get_playing_track(leader_track, @leader_creds)
    leader_pid = PlayingTrackSync.start_link(@leader_name, @leader_creds)

    mock_get_playing_track(follower_track, @follower_creds)
    follower_pid = PlayingTrackSync.start_link(@follower_name, @follower_creds)

    FollowerSupervisor.start_follow(@leader_name, @follower_name)

    {:ok,
     leader_track: leader_track,
     follower_track: follower_track,
     leader_pid: leader_pid,
     follower_pid: follower_pid,
     supervisor_pid: supervisor_pid}
  end
end
