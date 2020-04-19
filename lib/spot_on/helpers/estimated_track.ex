defmodule SpotOn.Helpers.EstimatedTrack do
  alias SpotOn.Gen.PlayingTrackSyncState
  alias SpotOn.SpotifyApi.PlayingTrack

  @progress_similarity_threshold_ms 50

  # The estimated_track is a clone of PlayingTrack with an API latency estimate applied.
  # If playing_track is not set, then nil return
  def get_estimated_track(%PlayingTrackSyncState{playing_track: nil}), do: nil

  # If playing_track is set, but it's not playing, no need to adjust progress_ms for latency.
  def get_estimated_track(%PlayingTrackSyncState{
        playing_track: track = %PlayingTrack{is_playing: false}
      }),
      do: track

  # If the playing_track is set, and estimated_api_ms is not set, then no need to adjust progress_ms for latency.
  def get_estimated_track(%PlayingTrackSyncState{
        playing_track: track = %PlayingTrack{},
        estimated_api_ms: 0
      }),
      do: track

  # playing_track is set properly. Lets adjust for latency.
  def get_estimated_track(state = %PlayingTrackSyncState{playing_track: track = %PlayingTrack{}}) do
    additional_delay =
      case track.is_playing do
        true -> state.estimated_api_ms
        _ -> 0
      end

    get_estimated_track(track, state.created_at, additional_delay)
  end

  def get_estimated_track(track = %PlayingTrack{is_playing: false}, _, _), do: track

  def get_estimated_track(
        track = %PlayingTrack{is_playing: true},
        created_at,
        additional_buffer_ms
      ) do
    millis_since_fetch = DateTime.diff(DateTime.utc_now(), created_at, :millisecond)

    new_progress_millis =
      min(
        track.progress_ms + additional_buffer_ms + millis_since_fetch,
        track.track.duration_ms
      )

    %{track | progress_ms: new_progress_millis}
  end

  def playing_is_approx_same(
        %PlayingTrackSyncState{playing_track: nil},
        %PlayingTrackSyncState{playing_track: nil}
      ),
      do: true

  def playing_is_approx_same(
        state1 = %PlayingTrackSyncState{playing_track: track1},
        state2 = %PlayingTrackSyncState{playing_track: track2}
      )
      when track1 != nil and track2 != nil do
    est1 = state1 |> get_estimated_track
    est2 = state2 |> get_estimated_track

    est1.track.song_uri == est2.track.song_uri &&
      abs(est1.progress_ms - est2.progress_ms) <
        @progress_similarity_threshold_ms &&
      est1.is_playing == est2.is_playing
  end

  def playing_is_approx_same(%PlayingTrackSyncState{}, %PlayingTrackSyncState{}),
    do: false
end
