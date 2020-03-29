defmodule SpotOnWeb.PlayingTrack do
  use Phoenix.LiveComponent
  alias SpotOn.SpotifyApi.PlayingTrack

  def update(%{playing_track: playing_track = %PlayingTrack{}}, socket), do:
    {:ok, socket
      |> assign(:playing_track, playing_track)
      |> assign_progress
    }

  def assign_progress(socket = %{assigns: %{playing_track: track = %PlayingTrack{}}}) do
    seconds = trunc(track.progress_ms / 1000)
    minutes = trunc(seconds / 60)
    seconds_remainder = seconds - (minutes * 60)
    seconds_remainder_string = seconds_remainder
      |> Integer.to_string
      |> String.pad_leading(2, "0")

    progress = "#{minutes}:#{seconds_remainder_string}"
    percentage_progress = trunc(track.progress_ms / track.track.duration_ms * 100)

    socket
    |> assign(:progress, progress)
    |> assign(:percentage_progress, percentage_progress)
  end

  def assign_progress(_), do: nil
end
