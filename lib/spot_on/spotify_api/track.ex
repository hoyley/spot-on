defmodule SpotOn.SpotifyApi.Track do
  alias SpotOn.SpotifyApi.Track
  defstruct [:song_name, :artist_name, :album_name, :small_image]

  def new(raw) do
    %{ "item" => %{"name" => song_name }} = raw
    %{ "item" => %{"album" => %{ "name" => album_name }}} = raw
    %{ "item" => %{"artists" => [%{"name" => artist_name}]}} = raw
    %Track{ song_name: song_name, artist_name: artist_name, album_name: album_name,
      small_image: get_small_image(raw)}
  end

  def new(song_name, artist_name, album_name) do
    %Track{ song_name: song_name, artist_name: artist_name, album_name: album_name }
  end

  def get_small_image(raw) do
    %{ "item" => %{"album" => %{ "images" => images }}} = raw
    images
      |> Enum.min_by(fn image -> image["height"] end)
      |> case do
        nil -> nil
        image -> image["url"]
      end
  end
end
