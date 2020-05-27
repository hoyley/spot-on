defmodule SpotOnWeb.AuthController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Authentication
  alias SpotOn.SpotifyApi.Authorization
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.Actions
  alias SpotOn.Model
  require Logger

  def authenticate(conn, params) do
    case Authentication.authenticate(conn, params) do
      %ApiSuccess{credentials: credentials} ->

        %ApiSuccess{result: %{id: user_name}, credentials: new_creds} =
          Actions.update_my_user_tokens(credentials)

        %{display_name: display_name} = Model.get_user_by_name(user_name)

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
        |> put_session("logged_in_user_display_name", display_name)
        |> redirect(to: params["state"])

      %ApiFailure{status: :refresh_revoked} ->
        conn
        |> redirect(to: "/logout")

      %ApiFailure{} = failure ->
        Logger.error(
          "Error when authenticating. Failure [#{failure.message}] HttpStatus [#{failure.status}] Status [#{
            failure.http_status
          }]"
        )

        redirect(conn, to: "/error")
    end
  end

  def authorize(conn, _params = %{"origin" => origin}) do
    redirect(conn, external: Authorization.url(origin))
  end
end
