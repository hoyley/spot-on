defmodule SpotOn.SpotifyApi.Player do
  use Responder
  alias SpotOn.SpotifyApi.Client

  def current_track(conn) do
    conn
    |> Client.get(current_track_url())
    |> handle_response
  end

  def play(conn, params) do
    conn
    |> Client.put(play_track_url(), params)
    |> handle_response
  end

  def pause(conn) do
    conn
    |> Client.put(pause_track_url())
    |> handle_response
  end

  def current_track_url() do
    "https://api.spotify.com/v1/me/player/currently-playing"
  end

  def play_track_url() do
    "https://api.spotify.com/v1/me/player/play"
  end

  def pause_track_url() do
    "https://api.spotify.com/v1/me/player/pause"
  end

  def build_response(body), do: body
end
