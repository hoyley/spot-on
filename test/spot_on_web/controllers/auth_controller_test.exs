defmodule SpotOn.AuthControllerTest do
  import Mox
  import SpotOn.Helpers.Defaults
  use SpotOnWeb.ConnCase
  use SpotOn.Helpers.MockHelper
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOnWeb.AuthController

  describe "authorization" do
    test "authorize call properly redirects to spotify login", %{conn: conn} do
      response =
        conn
        |> Cookies.set_refresh_cookie("refresh")
        |> Cookies.set_access_cookie("access")
        |> AuthController.authorize(%{"origin" => "/"})

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
        |> AuthController.authorize(%{"origin" => "/"})

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
      mock_authenticate()

      new_conn =
        conn
        |> Cookies.set_refresh_cookie(default_refresh_token())
        |> Cookies.set_access_cookie(default_access_token())

      new_conn
      |> Credentials.new()
      |> mock_get_my_profile()

      response =
        new_conn
        |> AuthController.authenticate(%{"code" => "spotify_code", "state" => "/"})

      assert redirected_to(response, 302) == "/"
    end
  end
end
