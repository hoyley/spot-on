defmodule SpotOn.SpotifyApi.PlayingTrack do
  alias SpotOn.SpotifyApi.Track
  alias SpotOn.SpotifyApi.PlayingTrack
  require Logger

  defstruct user_name: nil,
            progress_ms: nil,
            timestamp: nil,
            track: nil,
            is_playing: false

  def new(
        user_name,
        raw = %{
          "progress_ms" => progress_ms,
          "timestamp" => timestamp,
          "is_playing" => is_playing
        }
      ) do
    PlayingTrack.new(
      user_name,
      progress_ms,
      timestamp,
      is_playing,
      Track.new(raw)
    )
  end

  def new(_, _, _, _, nil), do: nil

  def new(user_name, progress_ms, timestamp, is_playing, %Track{} = track) do
    %PlayingTrack{
      user_name: user_name,
      progress_ms: progress_ms,
      timestamp: timestamp,
      is_playing: is_playing,
      track: track
    }
  end
end
