defmodule SpotOnWeb.PageControllerTest do
  use SpotOnWeb.ConnCase
  alias SpotOnWeb.PageController

  describe "page controller" do
    test "when no cookies in connection, redirect to authorize page", %{
      conn: conn
    } do
      response =
        conn
        |> PageController.index(nil)

      assert redirected_to(response, 302) == "/authorize?origin=/"
    end

    test "when logout, redirect to Spotify logout", %{conn: conn} do
      response =
        conn
        |> PageController.logout(nil)

      assert redirected_to(response, 302) ==
               "https://www.spotify.com/us/logout/"
    end
  end
end
