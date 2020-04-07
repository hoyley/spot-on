defmodule SpotOnWeb.AuthController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Authentication
  alias SpotOn.SpotifyApi.Authorization
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.Actions

  def authenticate(conn, params) do
    case Authentication.authenticate(conn, params) do
      %ApiSuccess{credentials: credentials} ->
        Cookies.set_cookies(conn, credentials)
        |> Actions.update_my_user_tokens()
        |> redirect(to: "/")

      %ApiFailure{} ->
        redirect(conn, to: "/error")
    end
  end

  def authorize(conn, _params) do
    redirect(conn, external: Authorization.url())
  end
end
