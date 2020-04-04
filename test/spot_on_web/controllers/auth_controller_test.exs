defmodule SpotOn.AuthControllerTest do
  import Mox
  use SpotOnWeb.ConnCase
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOnWeb.AuthController

  describe "authorization" do
    test "authorize call properly redirects to spotify login", %{conn: conn} do
      response =
        conn
        |> Cookies.set_refresh_cookie("refresh")
        |> Cookies.set_access_cookie("access")
        |> AuthController.authorize(nil)

      assert redirected_to(response, 302) =~
               "https://accounts.spotify.com/authorize"
    end
  end

  describe "authentication" do
    test "authorize call properly redirects to spotify login", %{conn: conn} do
      response =
        conn
        |> Cookies.set_refresh_cookie("refresh")
        |> Cookies.set_access_cookie("access")
        |> AuthController.authorize(nil)

      assert redirected_to(response, 302) =~
               "https://accounts.spotify.com/authorize"
    end

    test "when no code provided, authentication fails", %{conn: conn} do
      response =
        conn
        |> Cookies.set_refresh_cookie("refresh")
        |> Cookies.set_access_cookie("access")
        |> AuthController.authenticate(nil)

      assert redirected_to(response, 302) =~
               "/error"
    end

    test "when code provided and Spotify authenticates, authentication succeeds",
         %{conn: conn} do
      ClientBehaviorMock
      |> expect(:authenticate, fn url, _params ->
        assert url == "https://accounts.spotify.com/api/token"

        {:ok,
         %HTTPoison.Response{
           body: '{"access_token":"test"}'
         }}
      end)

      response =
        conn
        |> Cookies.set_refresh_cookie("refresh")
        |> Cookies.set_access_cookie("access")
        |> AuthController.authenticate(%{"code" => "spotify_code"})

      assert redirected_to(response, 302) == "/"
    end
  end
end
