defmodule SpotOn.Helpers.Helper do

  alias SpotOn.SpotifyApi.PlayingTrack
  import SpotOn.Helpers.Defaults

  defmacro __using__(_) do
    quote do
      def to_json(nil), do: ""
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
          is_playing: playing_track.is_playing,
          item: %{
            name: playing_track.track.song_name,
            duration_ms: playing_track.track.duration_ms,
            uri: playing_track.track.song_uri,
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

      def to_map(json) do
        json |> Poison.decode
      end

      def update(track = %PlayingTrack{}, attrs \\ %{}) do
        track_map = track
        |> to_map
        |> deep_merge(attrs)

        PlayingTrack.new(track.user_name, track_map)
      end

      def add_artist(playing_track = %{}, artist_name) do
        playing_track
        |> update_in([:item, :artists], &(&1 ++ [%{ name: artist_name}]))
      end

      def assert_equals(track1 = %PlayingTrack{}, track2 = %PlayingTrack{}) do
        assert track1.user_name === track2.user_name
        assert track1.progress_ms === track2.progress_ms
        assert track1.timestamp === track2.timestamp
        assert track1.is_playing === track2.is_playing
        assert track1.track.song_name === track2.track.song_name
        assert track1.track.artist_name === track2.track.artist_name
        assert track1.track.album_name === track2.track.album_name
        assert track1.track.duration_ms === track2.track.duration_ms
        assert track1.track.song_uri === track2.track.song_uri
      end

      def deep_merge(left, right) do
        Map.merge(left, right, &deep_resolve/3)
      end

      defp deep_resolve(_key, left = %{}, right = %{}) do
        deep_merge(left, right)
      end

      defp deep_resolve(_key, _left, right), do: right

      def new_paused_track(user_name) do
        default_playing_track()
        |> Map.put(:user_name, user_name)
        |> Map.put(:is_playing, false)
      end

      def new_playing_track(%{user_name: user_name, song_uri: song_uri, progress_ms: progress_ms}) do
        default_playing_track()
        |> Map.put(:user_name, user_name)
        |> Map.put(:is_playing, true)
        |> Map.put(:progress_ms, progress_ms)
        |> put_in([Access.key(:track), Access.key(:song_uri)], song_uri)
      end

      def new_playing_track(%{user_name: user_name, song_uri: song_uri}), do:
        new_playing_track(%{user_name: user_name, song_uri: song_uri, progress_ms: default_playing_progress_ms()})

      def new_playing_track(user_name) do
        default_playing_track()
        |> Map.put(:user_name, user_name)
        |> Map.put(:is_playing, true)
      end
    end
  end
end
