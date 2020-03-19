defmodule SpotOn.Gen.PlayingTrackSyncState do
  alias SpotOn.Gen.PlayingTrackSyncState
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.SpotifyApi.Credentials

  @enforce_keys [:user_id]
  defstruct user_id: nil,
            credentials: nil,
            created_at: nil,
            playing_track: nil,
            estimated_api_ms: 0

  def new(user_id) when is_binary(user_id) do
    %PlayingTrackSyncState{ user_id: user_id, created_at: DateTime.utc_now }
  end

  def new(user_id, credentials = %Credentials{}) when is_binary(user_id) do
    %PlayingTrackSyncState{ user_id: user_id, credentials: credentials, created_at: DateTime.utc_now }
  end

  def new(user_id, credentials = %Credentials{}, playing_track, estimated_api_ms)
      when is_binary(user_id) do
    %PlayingTrackSyncState{ user_id: user_id, credentials: credentials, playing_track: playing_track,
      estimated_api_ms: estimated_api_ms, created_at: DateTime.utc_now }
  end

  # The estimated_track is a clone of PlayingTrack with an API latency estimate applied.
  # If playing_track is not set, then nil return
  def get_estimated_track(%PlayingTrackSyncState{playing_track: nil}), do: nil

  # If playing_track is set, but it's not playing, no need to adjust progress_ms for latency.
  def get_estimated_track(%PlayingTrackSyncState{playing_track:
    track = %PlayingTrack{is_playing: false}}), do: track

  # If the playing_track is set, and estimated_api_ms is not set, then no need to adjust progress_ms for latency.
  def get_estimated_track(%PlayingTrackSyncState{playing_track:
    track = %PlayingTrack{}, estimated_api_ms: 0}), do: track

  # playing_track is set properly. Lets adjust for latency.
  def get_estimated_track(state = %PlayingTrackSyncState{playing_track: track = %PlayingTrack{}}) do
    millis_since_fetch = DateTime.diff(DateTime.utc_now, state.created_at, :millisecond)
    new_progress_millis = min(track.progress_ms + state.estimated_api_ms + millis_since_fetch, track.track.duration_ms)

    %{ track | progress_ms: new_progress_millis}
  end
end