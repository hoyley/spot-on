defmodule SpotOn.SpotifyApi.PlayingTrack do
  alias SpotOn.SpotifyApi.Track
  alias SpotOn.SpotifyApi.PlayingTrack
  require Logger

  defstruct user_name: nil,
    progress_ms: nil,
    timestamp: nil,
    track: nil

  def new(user_name) do
    %PlayingTrack{ user_name: user_name }
  end

  def new(user_name, raw = %{ "progress_ms" => progress_ms, "timestamp" => timestamp}) do
    PlayingTrack.new(user_name, progress_ms, timestamp, Track.new(raw))
  end

  def new(user_name, progress_ms, timestamp, %Track{} = track) do
    %PlayingTrack{ user_name: user_name, progress_ms: progress_ms, timestamp: timestamp, track: track }
  end
end
