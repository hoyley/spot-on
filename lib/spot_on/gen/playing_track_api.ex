defmodule SpotOn.Gen.PlayingTrackApi do
  use GenServer
  alias SpotOn.Gen.PlayingTrackApi
  alias SpotOn.Model
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Track
  require Logger

  @refetch_milli_delay 10 * 1000

  @enforce_keys [:user_id]
  defstruct user_id: nil,
            credentials: nil,
            created_at: nil,
            playing_track: nil,
            estimated_api_ms: 0

  def new(user_id) when is_binary(user_id) do
    %PlayingTrackApi{ user_id: user_id, created_at: DateTime.utc_now }
  end

  def new(user_id, credentials = %Credentials{}) when is_binary(user_id) do
    %PlayingTrackApi{ user_id: user_id, credentials: credentials, created_at: DateTime.utc_now }
  end

  def new(user_id, credentials = %Credentials{}, playing_track, estimated_api_ms)
      when is_binary(user_id) do
    %PlayingTrackApi{ user_id: user_id, credentials: credentials, playing_track: playing_track,
                      estimated_api_ms: estimated_api_ms, created_at: DateTime.utc_now }
  end

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, PlayingTrackApi.new(user_id), name: {:global, user_id})
  end

  def start_link(user_id, creds = %Credentials{}) do
    GenServer.start_link(__MODULE__, PlayingTrackApi.new(user_id, creds), name: {:global, user_id})
  end

  def get(user_id), do:
    get_playing_track_api(user_id)
    |> Map.get(:playing_track)

  def get_estimated(user_id), do:
    get_playing_track_api(user_id)
    |> get_estimated_track

  def get_playing_track_api(user_id) do
    start_link(user_id)
    GenServer.call({:global, user_id}, :get)
  end

  @impl true
  def init(state = %PlayingTrackApi{}) do
    Logger.debug 'Started GenServer for PlayingTrack[#{state.user_id}]'

    refresh_state(state, :ok)
  end

  @impl true
  def handle_call(:get, _from, state = %PlayingTrackApi{}) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:get, state = %PlayingTrackApi{}) do
    refresh_state(state, :noreply)
  end

  defp refresh_state(state = %PlayingTrackApi{}, response_token) do
    try do
      new_state = get_playing_track(state)

      schedule_get(new_state)
      {response_token, new_state}
    rescue
      error -> Logger.error Exception.format(:error, error, __STACKTRACE__)
               raise error
    end
  end

  defp schedule_get(%PlayingTrackApi{playing_track: %PlayingTrack{progress_ms: progress, track:
      %Track{duration_ms: duration}}}) do
    min(duration - progress, @refetch_milli_delay)
    |> schedule_get
  end

  defp schedule_get(%PlayingTrackApi{}), do: schedule_get(@refetch_milli_delay)

  defp schedule_get(delay) do
    Process.send_after(self(), :get, delay)
  end

  defp get_playing_track(state = %PlayingTrackApi{credentials: nil}) do
    credentials = Model.get_user_token_by_user_name(state.user_id)
    |> Credentials.new
    new_state = %{state | credentials: credentials}

    get_playing_track(new_state)
  end

  defp get_playing_track(state = %PlayingTrackApi{}) do
    function_call = fn s -> Api.get_playing_track(s.user_id, s.credentials) end

    # We will time the call to estimate the API response time
    {micros, success = %ApiSuccess{}} = :timer.tc(function_call, [state])

    total_millis = micros / 1000
    estimated_one_way_millis = total_millis / 2

    PlayingTrackApi.new(state.user_id, success.credentials, success.result, estimated_one_way_millis)
  end

  # The estimated_track is a clone of PlayingTrack with an API latency estimate applied.
  # If playing_track is not set, then nil return
  def get_estimated_track(%PlayingTrackApi{playing_track: nil}), do: nil

  # If playing_track is set, but it's not playing, no need to adjust progress_ms for latency.
  def get_estimated_track(%PlayingTrackApi{playing_track:
    track = %PlayingTrack{is_playing: false}}), do: track

  # If the playing_track is set, and estimated_api_ms is not set, then no need to adjust progress_ms for latency.
  def get_estimated_track(%PlayingTrackApi{playing_track:
    track = %PlayingTrack{}, estimated_api_ms: 0}), do: track

  # playing_track is set properly. Lets adjust for latency.
  def get_estimated_track(state = %PlayingTrackApi{playing_track: track = %PlayingTrack{}}) do
    millis_since_fetch = DateTime.diff(DateTime.utc_now, state.created_at, :millisecond)
    new_progress_millis = min(track.progress_ms + state.estimated_api_ms + millis_since_fetch, track.track.duration_ms)

    %{ track | progress_ms: new_progress_millis}
  end
end
