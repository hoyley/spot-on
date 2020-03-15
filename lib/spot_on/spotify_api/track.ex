defmodule SpotOn.SpotifyApi.Track do
  alias SpotOn.SpotifyApi.Track
  defstruct [:song_name, :artist_name, :album_name, :small_image, :duration_ms]

  def new(raw) do
    %{ "item" => %{"name" => song_name }} = raw
    %{ "item" => %{"duration_ms" => duration_ms }} = raw
    %{ "item" => %{"album" => %{ "name" => album_name }}} = raw

    %Track{ song_name: song_name, artist_name: get_artist_name(raw), album_name: album_name,
      small_image: get_small_image(raw), duration_ms: duration_ms}
  end

  def new(song_name, artist_name, album_name, small_image, duration_ms) do
    %Track{ song_name: song_name, artist_name: artist_name, album_name: album_name,
      small_image: small_image, duration_ms: duration_ms}
  end

  def get_small_image(raw) do
    raw
      |> get_images
      |> Enum.min_by(fn image -> image["height"] end, fn -> nil end)
      |> case do
        nil -> nil
        image -> image["url"]
      end
  end

  defp get_images(%{ "item" => %{"album" => %{ "images" => images }}}), do: images
  defp get_images(_), do: []

  def get_artist_name(raw) do
    # There might be multiple artists, so we comma separate them
    %{ "item" => %{"artists" => artists}} = raw
    Enum.map_join(artists, ", ", fn artist -> artist["name"] end)
  end
end
