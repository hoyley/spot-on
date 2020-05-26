defmodule SpotOnWeb.AuthController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Authentication
  alias SpotOn.SpotifyApi.Authorization
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.Actions
  require Logger

  def authenticate(conn, params) do
    case Authentication.authenticate(conn, params) do
      %ApiSuccess{credentials: credentials} ->
        %ApiSuccess{result: %{id: user_name}, credentials: new_creds} =
          Actions.update_my_user_tokens(credentials)

        Logger.info(
          "Authenticating user. User identified as [#{user_name}]. Redirecting to [#{
            params["state"]
          }]"
        )

        conn
        |> Cookies.set_cookies(new_creds)
        |> put_session("spotify_access_token", new_creds.access_token)
        |> put_session("spotify_refresh_token", new_creds.refresh_token)
        |> put_session("logged_in_user_name", user_name)
        |> redirect(to: params["state"])

      %ApiFailure{} ->
        redirect(conn, to: "/error")
    end
  end

  def authorize(conn, _params = %{"origin" => origin}) do
    redirect(conn, external: Authorization.url(origin))
  end
end
