defmodule SpotOn.SpotifyApi.Track do
  alias SpotOn.SpotifyApi.Track
  defstruct [:song_name, :artist_name, :album_name]

  def new(raw) do
    %{ "item" => %{"name" => song_name }} = raw
    %{ "item" => %{"album" => %{ "name" => album_name }}} = raw
    %{ "item" => %{"artists" => [%{"name" => artist_name}]}} = raw
    
    Track.new(song_name, artist_name, album_name)
  end

  def new(song_name, artist_name, album_name) do
    %Track{ song_name: song_name, artist_name: artist_name, album_name: album_name }
  end
end
