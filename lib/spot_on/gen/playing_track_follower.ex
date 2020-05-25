defmodule SpotOn.Gen.PlayingTrackFollower do
  use GenServer
  alias SpotOn.Gen.PlayingTrackFollower
  alias SpotOn.Gen.PlayingTrackSync
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.PubSub
  import SpotOn.Helpers.EstimatedTrack
  require Logger

  @refresh_delay_ms Application.get_env(:spot_on, :follower_poll_ms)
  @progress_threshold Application.get_env(:spot_on, :follower_threshold_ms)

  @type follow_state ::
          :unknown
          | :follow_initiated
          | :leader_inactive
          | :follower_inactive
          | :following_paused
          | :following_different_song
          | :following_outside_threshold
          | :following
          | :stopped_following

  # It appears that the Spotify API lags when setting song progress. This is to account for some of
  # that volatility
  @expected_api_delay_ms Application.get_env(
                           :spot_on,
                           :spotify_set_playing_song_delay_ms
                         )

  @enforce_keys [:leader_name, :follower_name]
  defstruct leader_name: nil,
            follower_name: nil,
            state: :follow_state_unkown,
            previous_state: :follow

  def new(leader_name, follower_name) do
    %PlayingTrackFollower{
      leader_name: leader_name,
      follower_name: follower_name
    }
  end

  def start_link(leader_name, follower_name),
    do: start_link(PlayingTrackFollower.new(leader_name, follower_name))

  def start_link(follower = %PlayingTrackFollower{}) do
    GenServer.start_link(__MODULE__, follower,
      name: {:global, {follower.leader_name, follower.follower_name}}
    )
  end

  @impl true
  def init(state = %PlayingTrackFollower{}) do
    Process.flag(:trap_exit, true)

    {:ok, state |> update_state(:follow_initiated) |> refresh}
  end

  @impl true
  def handle_info(:refresh, state = %PlayingTrackFollower{}) do
    {:noreply, state |> refresh}
  end

  @impl true
  def handle_info({:EXIT, _pid, _reason}, state = %PlayingTrackFollower{}),
    do: {:noreply, state |> update_state(:stopped_following)}

  @impl true
  def handle_info(msg, state = %PlayingTrackFollower{}) do
    Logger.error('PlayingTrackFollower received unexpected message: #{inspect(msg)}')

    {:noreply, state}
  end

  def stop_follow(leader_name, follower_name) do
    :global.whereis_name({leader_name, follower_name})
    |> stop_follow()
  end

  defp stop_follow(:undefined), do: nil

  defp stop_follow(pid) when is_pid(pid) do
    pid
    |> Process.exit(:ok)

    pid
  end

  defp refresh(state = %PlayingTrackFollower{}) do
    try do
      leader_track = PlayingTrackSync.get_sync_state(state.leader_name)
      follower_track = PlayingTrackSync.get_sync_state(state.follower_name)
      leader_track_estimated = leader_track |> get_estimated_track
      follower_track_estimated = follower_track |> get_estimated_track

      new_state = refresh(leader_track_estimated, follower_track_estimated, state)
      schedule_refresh()
      new_state
    rescue
      error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        raise error
    end
  end

  # When the leader is not active, do nothing
  defp refresh(nil, _, state = %PlayingTrackFollower{}), do: state |> update_state(:leader_inactive)

  # When the follower is not active, have the follower stop following
  defp refresh(_, nil, state = %PlayingTrackFollower{}),
    do: state |> update_state(:follower_inactive)

  # When the leader is not playing but the follower is playing, force pause the follower
  defp refresh(
         _leader = %PlayingTrack{is_playing: false},
         _follower = %PlayingTrack{is_playing: true},
         state = %PlayingTrackFollower{}
       ),
       do: force_pause(state)

  # When the leader is not playing and the follower is not playing, do nothing
  defp refresh(
         _leader = %PlayingTrack{is_playing: false},
         _follower = %PlayingTrack{is_playing: false},
         state = %PlayingTrackFollower{}
       ),
       do: state |> update_state(:following_paused)

  # When the leader is playing, and the follower is active, only update the follower under certain conditions
  defp refresh(
         leader = %PlayingTrack{},
         follower = %PlayingTrack{},
         state = %PlayingTrackFollower{}
       ) do
    same_song = leader.track.song_uri === follower.track.song_uri
    progress_difference = leader.progress_ms - follower.progress_ms
    outside_threshold = abs(progress_difference) > @progress_threshold

    refresh(leader, follower, state, same_song, outside_threshold)
  end

  defp refresh(
         leader = %PlayingTrack{},
         _follower = %PlayingTrack{},
         state = %PlayingTrackFollower{},
         _same_song = false,
         _outside_threshold
       ) do
    state |> update_state(:following_different_song) |> force_follow(leader)
  end

  defp refresh(
         leader = %PlayingTrack{},
         follower = %PlayingTrack{},
         state = %PlayingTrackFollower{},
         _same_song = true,
         _outside_threshold = true
       ) do
    Logger.info(
      'FollowerOutsideThreshold -- #{state.follower_name} | #{state.leader_name} | #{state.state} (follower | leader | state) -- Follower differential [#{
        follower.progress_ms - leader.progress_ms
      }ms]'
    )

    state |> update_state(:following_outside_threshold) |> force_follow(leader)
  end

  defp refresh(
         _leader = %PlayingTrack{},
         _follower = %PlayingTrack{},
         state = %PlayingTrackFollower{},
         _same_song = true,
         _outside_threshold = false
       ),
       do: state |> update_state(:following)

  defp force_follow(state = %PlayingTrackFollower{}, leader = %PlayingTrack{}) do
    playing_track =
      state.follower_name
      |> PlayingTrackSync.get_sync_state()

    new_progress =
      leader.progress_ms + playing_track.estimated_api_ms +
        @expected_api_delay_ms

    Logger.info(
      'FollowerOusideThreshold -- Requesting Update -- Follower [#{state.follower_name}], Context [#{
        leader.track.song_uri
      }], Song Name [#{leader.track.song_name}], Position [#{new_progress}].'
    )

    playing_track
    |> Map.get(:credentials)
    |> Api.play_track(leader.track.song_uri, new_progress)

    state
  end

  defp force_pause(state = %PlayingTrackFollower{}) do
    Logger.info(
      'LeaderPaused -- #{state.follower_name} | #{state.leader_name} | #{state.state} (follower | leader | state) -- #{
        state.follower_name
      }] will be paused because leader [#{state.leader_name}] is paused.'
    )

    state.follower_name
    |> PlayingTrackSync.get_sync_state()
    |> Map.get(:credentials)
    |> Api.pause_track()

    state
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_delay_ms)
  end

  @spec update_state(%PlayingTrackFollower{}, follow_state) :: %PlayingTrackFollower{}
  defp update_state(follow = %PlayingTrackFollower{}, new_state) do
    new_follow = %PlayingTrackFollower{
      leader_name: follow.leader_name,
      follower_name: follow.follower_name,
      state: new_state,
      previous_state: follow.state
    }

    if new_follow.state !== new_follow.previous_state do
      PubSub.publish_follow_state(new_follow)
    end

    new_follow
  end
end
