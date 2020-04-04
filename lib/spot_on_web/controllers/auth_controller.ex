defmodule SpotOnWeb.AuthController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Authentication
  alias SpotOn.SpotifyApi.Authorization
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Cookies

  def authenticate(conn, params) do
    case Authentication.authenticate(conn, params) do
      %ApiSuccess{credentials: credentials} ->
        Cookies.set_cookies(conn, credentials)
        |> redirect(to: "/")

      %ApiFailure{} ->
        redirect(conn, to: "/error")
    end
  end

  def authorize(conn, _params) do
    redirect(conn, external: Authorization.url())
  end
end
