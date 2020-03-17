defmodule SpotOn.Gen.PlayingTrackFollower do
  use GenServer
  alias SpotOn.Gen.PlayingTrackFollower
  alias SpotOn.Gen.PlayingTrackApi
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Api
  require Logger

  @refresh_delay_ms 10 * 1000
  @progress_threshold 2 * 1000

  # It apears that the spotify API lags when setting song progress. This is to account for some of that volatility
  @expected_api_delay_ms 100

  @enforce_keys [:leader_name, :follower_name]
  defstruct leader_name: nil,
            follower_name: nil

  def new(leader_name, follower_name) do
    %PlayingTrackFollower{ leader_name: leader_name, follower_name: follower_name }
  end

  def start_link(leader_name, follower_name), do: start_link(PlayingTrackFollower.new(leader_name, follower_name))

  def start_link(follower = %PlayingTrackFollower{}) do
    GenServer.start_link(__MODULE__, follower, name: {:global, {follower.leader_name, follower.follower_name}})
  end

  @impl true
  def init(state = %PlayingTrackFollower{}) do
    Logger.info '[#{state.follower_name}] is now following [#{state.leader_name}]'
    refresh(state, :ok)
  end

  @impl true
  def handle_info(:refresh, state = %PlayingTrackFollower{}) do
    refresh(state, :noreply)
  end

  defp refresh(state = %PlayingTrackFollower{}, reply_token) do
    try do
      new_state = refresh(state)
      schedule_refresh()
      {reply_token, new_state}
    rescue
      error -> Logger.error Exception.format(:error, error, __STACKTRACE__)
               raise error
    end
  end

  defp refresh(state = %PlayingTrackFollower{}) do
    leader_track = PlayingTrackApi.get_playing_track_api(state.leader_name)
    follower_track = PlayingTrackApi.get_playing_track_api(state.follower_name)
    leader_track_estimated = leader_track |> PlayingTrackApi.get_estimated_track
    follower_track_estimated = follower_track |> PlayingTrackApi.get_estimated_track

    refresh(leader_track_estimated, follower_track_estimated, state)
  end

  # When the leader is not active, do nothing
  defp refresh(nil, _, state = %PlayingTrackFollower{}), do: state

  # When the follower is not active, do nothing
  defp refresh(_, nil, state = %PlayingTrackFollower{}), do: state

  # When the leader is not playing but the following is playing, force pause the follower
  defp refresh(_leader = %PlayingTrack{is_playing: false}, _follower = %PlayingTrack{is_playing: true},
         state = %PlayingTrackFollower{}), do: force_pause(state)

  # When the leader is not playing and the follower is not playing, do nothing
  defp refresh(_leader = %PlayingTrack{is_playing: false}, _follower = %PlayingTrack{is_playing: false},
         state = %PlayingTrackFollower{}), do: state

  # When the leader is playing, and the follower is active, only update the follower under certain conditions
  defp refresh(leader = %PlayingTrack{}, follower = %PlayingTrack{}, state = %PlayingTrackFollower{}) do
    same_song = (leader.track.song_uri === follower.track.song_uri)
    progress_difference = leader.progress_ms - follower.progress_ms
    outside_threshold = abs(progress_difference) > @progress_threshold

    if !same_song do
      Logger.info 'Tracking follower [#{state.follower_name}] and leader [#{state.leader_name}]. Songs are not the same.'
    else
      Logger.info 'Tracking follower [#{state.follower_name}] and leader [#{state.leader_name}] on the same song. Leader progress [#{leader.progress_ms}], follower progress [#{follower.progress_ms}], difference [#{progress_difference}]'
    end

    # Only update if leader and follower are either on different songs or they are not in sync (within threshold)
    case !same_song || outside_threshold do
      true -> force_follow(leader, state)
      false -> state
    end
  end

  defp force_follow(leader = %PlayingTrack{}, state = %PlayingTrackFollower{}) do
    playing_track = state.follower_name
    |> PlayingTrackApi.get_playing_track_api()

    new_progress = (leader.progress_ms + playing_track.estimated_api_ms + @expected_api_delay_ms)
    Logger.info 'Follower [#{state.follower_name}] needs update from [#{leader.user_name}] -- song context [#{leader.track.song_uri}] song name [#{leader.track.song_name}] position [#{new_progress}].'

    playing_track
      |> Map.get(:credentials)
      |> Api.play_track(leader.track.song_uri, new_progress)

    state
  end

  defp force_pause(state = %PlayingTrackFollower{}) do
    Logger.info 'Follower [#{state.follower_name}] will be paused because leader [#{state.leader_name}] is paused.'

    state.follower_name
    |> PlayingTrackApi.get_playing_track_api()
    |> Map.get(:credentials)
    |> Api.pause_track()

    state
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_delay_ms)
  end

end
