defmodule SpotOn.Helper do

  alias SpotOn.SpotifyApi.PlayingTrack

  defmacro __using__(_) do
    quote do
      def to_json(playing_track = %PlayingTrack{}) do
        to_map(playing_track)
        |> to_json
      end

      def to_json(map = %{}) do
        map |> Poison.encode!
      end

      def to_map(playing_track = %PlayingTrack{}) do
        %{
          id: playing_track.user_name,
          progress_ms: playing_track.progress_ms,
          timestamp: playing_track.timestamp,
          item: %{
            name: playing_track.track.song_name,
            album: %{
              name: playing_track.track.album_name
            },
            artists: [
              %{
                name: playing_track.track.artist_name
              }
            ]
          }
        }
      end

      def add_artist(playing_track = %{}, artist_name) do
        playing_track
        |> update_in([:item, :artists], &(&1 ++ [%{ name: artist_name}]))
      end

      def assert_equals(track1 = %PlayingTrack{}, track2 = %PlayingTrack{}) do
        assert track1.user_name === track2.user_name
        assert track1.progress_ms === track2.progress_ms
        assert track1.timestamp === track2.timestamp
        assert track1.track.song_name === track2.track.song_name
        assert track1.track.artist_name === track2.track.artist_name
        assert track1.track.album_name === track2.track.album_name
      end
    end
  end
end
