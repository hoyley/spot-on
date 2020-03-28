defmodule SpotOnWeb.PlayingTrack do
  use Phoenix.LiveComponent
  alias SpotOn.SpotifyApi.PlayingTrack

  def update(%{playing_track: playing_track = %PlayingTrack{}}, socket) do
    new_socket = socket
    |> assign(:playing_track, playing_track)

    {:ok, new_socket}
  end
end
