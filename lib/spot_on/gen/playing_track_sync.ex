defmodule SpotOn.Gen.PlayingTrackSync do
  use GenServer
  alias SpotOn.Gen.PlayingTrackSyncState
  alias SpotOn.Model
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Track
  import SpotOn.Helpers.EstimatedTrack
  require Logger

  @refetch_milli_delay Application.get_env(:spot_on, :playing_track_poll_ms)

  def start_link(user_id) do
    GenServer.start_link(__MODULE__, PlayingTrackSyncState.new(user_id), name: {:global, user_id})
  end

  def start_link(user_id, creds = %Credentials{}) do
    GenServer.start_link(__MODULE__, PlayingTrackSyncState.new(user_id, creds),
      name: {:global, user_id}
    )
  end

  def get_sync_state(user_id) do
    start_link(user_id)
    GenServer.call({:global, user_id}, :get)
  end

  def get(user_id) do
    get_sync_state(user_id)
    |> Map.get(:playing_track)
  end

  @impl true
  def init(state = %PlayingTrackSyncState{}) do
    Logger.info('Syncing the currently playing track for [#{state.user_id}]')
    refresh_state(state, :ok)
  end

  @impl true
  def handle_call(:get, _from, state = %PlayingTrackSyncState{}) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:get, state = %PlayingTrackSyncState{}) do
    refresh_state(state, :noreply)
  end

  def handle_info({:EXIT, _pid, _reason}, state = %PlayingTrackSyncState{}) do
    Logger.info('Stopped syncing the currently playing track for [#{state.user_id}]')
  end

  def handle_info(unknown_message, state = %PlayingTrackSyncState{}) do
    Logger.error(
      'Unknown message received by PlayingTrackSync GenServer while syncing track for [#{
        state.user_id
      }] -- #{inspect(unknown_message)}'
    )
  end

  def stop_sync(:undefined), do: nil

  def stop_sync(pid) when is_pid(pid) do
    pid
    |> Process.exit(:ok)

    pid
  end

  def stop_sync(user_name) do
    :global.whereis_name(user_name)
    |> stop_sync()
  end

  defp refresh_state(state = %PlayingTrackSyncState{}, response_token) do
    try do
      new_state = get_playing_track(state)

      # If the song has changed, publish changes to pubsub
      publish_changes(state, new_state)

      schedule_get(new_state)
      {response_token, new_state}
    rescue
      error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        raise error
    end
  end

  defp schedule_get(%PlayingTrackSyncState{
         playing_track: %PlayingTrack{
           progress_ms: progress,
           track: %Track{duration_ms: duration}
         }
       }) do
    min(duration - progress, @refetch_milli_delay)
    |> schedule_get
  end

  defp schedule_get(%PlayingTrackSyncState{}),
    do: schedule_get(@refetch_milli_delay)

  defp schedule_get(delay) do
    Process.send_after(self(), :get, delay)
  end

  defp get_playing_track(state = %PlayingTrackSyncState{credentials: nil}) do
    credentials =
      Model.get_user_token_by_user_name(state.user_id)
      |> Credentials.new()

    new_state = %{state | credentials: credentials}

    get_playing_track(new_state)
  end

  defp get_playing_track(state = %PlayingTrackSyncState{}) do
    function_call = fn s -> Api.get_playing_track(s.user_id, s.credentials) end

    # We will time the call to estimate the API response time
    {micros, result} = :timer.tc(function_call, [state])

    total_millis = micros / 1000
    estimated_one_way_millis = total_millis / 2

    case result do
      failure = %ApiFailure{} ->
        Logger.error(
          "Error trying to sync playing track for user [#{state.user_id}]. Status [#{failure.status}], HTTP Status [#{
            failure.http_status
          }], Message [#{failure.message}]"
        )

        PlayingTrackSyncState.new(
          state.user_id,
          state.credentials,
          nil,
          estimated_one_way_millis
        )

      %ApiSuccess{result: track, credentials: new_creds} ->
        PlayingTrackSyncState.new(
          state.user_id,
          new_creds,
          track,
          estimated_one_way_millis
        )
    end
  end

  defp publish_changes(
         old_state = %PlayingTrackSyncState{},
         new_state = %PlayingTrackSyncState{}
       ) do
    unless playing_is_approx_same(new_state, old_state) do
      track = get_estimated_track(new_state)
      SpotOn.PubSub.publish_playing_track_update(new_state.user_id, track)
    end
  end
end
