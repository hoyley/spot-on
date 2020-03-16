defmodule SpotOn.Gen.PlayingTrackFollower do
  use GenServer
  alias SpotOn.Gen.PlayingTrackFollower
  alias SpotOn.Gen.PlayingTrackApi
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.Actions
  require Logger

  @refresh_delay_ms 1 * 1000
  @progress_threshold 1 * 1000

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

  defp refresh(nil, _, state = %PlayingTrackFollower{}), do: state

  defp refresh(_leader = %PlayingTrack{is_playing: false}, _follower = %PlayingTrack{is_playing: true},
         state = %PlayingTrackFollower{}), do: force_pause(state)

  defp refresh(_leader = %PlayingTrack{is_playing: false}, _follower = %PlayingTrack{is_playing: false},
         state = %PlayingTrackFollower{}), do: state

  defp refresh(leader = %PlayingTrack{}, follower = %PlayingTrack{}, state = %PlayingTrackFollower{}) do
    same_song = (leader.track.song_uri === follower.track.song_uri)
    outside_threshold = abs(leader.progress_ms - follower.progress_ms) > @progress_threshold

    case !same_song || outside_threshold do
      true -> force_follow(leader, state)
      false -> state
    end
  end

  defp refresh(leader = %PlayingTrack{}, nil, state = %PlayingTrackFollower{}), do: force_follow(leader, state)

  defp force_follow(leader = %PlayingTrack{}, state = %PlayingTrackFollower{}) do
    Logger.info 'Follower [#{state.follower_name}] needs update from [#{leader.user_name}] -- song context ' +
      '[#{leader.track.song_uri}] song name [#{leader.track.song_name}] position [#{leader.progress_ms}].'
    Actions.play_track(state.follower_name, leader.track.song_uri, leader.progress_ms)
    state
  end

  defp force_pause(state = %PlayingTrackFollower{}) do
    Logger.info 'Follower [#{state.follower_name}] will be paused because leader [#{state.leader_name}] is paused.'
    Actions.pause_track(state.follower_name)
    state
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_delay_ms)
  end

end
