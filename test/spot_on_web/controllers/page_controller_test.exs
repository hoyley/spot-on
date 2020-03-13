defmodule SpotOnWeb.PageControllerTest do
  use SpotOnWeb.ConnCase
  alias SpotOnWeb.PageController

  describe "page controller" do
    test "when no cookies in connection, redirect to authorize page", %{conn: conn} do
      response = conn
                 |> PageController.index(nil)

      assert redirected_to(response, 302) == "/authorize"
    end

    test "when logout, redirect to Spotify logout", %{conn: conn} do
      response = conn
                 |> PageController.logout(nil)

      assert redirected_to(response, 302) == "https://www.spotify.com/us/logout/"
    end

#    test "when cookies in connection, ", %{conn: conn} do
#      credentials = Credentials.new("access", "refresh")
#
#      ClientBehaviorMock
#      |> expect(:get, fn (creds, url) ->
#        assert url === "https://api.spotify.com/v1/me"
#        assert creds.access_token === "access"
#        assert creds.refresh_token === "refresh"
#
#        {:ok, %HTTPoison.Response{body: '{ "id": "spotify_id"}'}}
#      end)
#
#      ClientBehaviorMock
#      |> expect(:get, fn (creds, url) ->
#        assert url === "https://api.spotify.com/v1/me/player/currently-playing"
#        assert creds.access_token === "access"
#        assert creds.refresh_token === "refresh"
#
#        {:ok, %HTTPoison.Response{
#                        body: track("spotify_id", 1000, 0, "my humps", "some album", "some artist")}}
#      end)
#
#      conn |> PageController.index(credentials)
#    end
#
#    def track(id, progress, timestamp, song_name, album_name, artist_name) do
#      %{
#        id: id,
#        progress_ms: progress,
#        timestamp: timestamp,
#        item: %{
#          name: song_name,
#          album: %{
#            name: album_name
#          },
#          artists: [
#            %{
#              name: artist_name
#            }
#          ]
#        }
#      }
#      |> Poison.encode!
#    end

  end
end
