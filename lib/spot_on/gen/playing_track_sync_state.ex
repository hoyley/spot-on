defmodule SpotOn.Gen.PlayingTrackSyncState do
  alias SpotOn.Gen.PlayingTrackSyncState
  alias SpotOn.SpotifyApi.Credentials

  @enforce_keys [:user_id]
  defstruct user_id: nil,
            credentials: nil,
            created_at: nil,
            playing_track: nil,
            estimated_api_ms: 0

  def new(user_id) when is_binary(user_id) do
    %PlayingTrackSyncState{user_id: user_id, created_at: DateTime.utc_now()}
  end

  def new(user_id, credentials = %Credentials{}) when is_binary(user_id) do
    %PlayingTrackSyncState{
      user_id: user_id,
      credentials: credentials,
      created_at: DateTime.utc_now()
    }
  end

  def new(
        user_id,
        credentials = %Credentials{},
        playing_track,
        estimated_api_ms
      )
      when is_binary(user_id) do
    %PlayingTrackSyncState{
      user_id: user_id,
      credentials: credentials,
      playing_track: playing_track,
      estimated_api_ms: estimated_api_ms,
      created_at: DateTime.utc_now()
    }
  end
end
