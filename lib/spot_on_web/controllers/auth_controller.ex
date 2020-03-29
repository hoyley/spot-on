defmodule SpotOnWeb.AuthController do
  use SpotOnWeb, :controller
  alias SpotOn.SpotifyApi.Authentication
  alias SpotOn.SpotifyApi.Authorization

  def authenticate(conn, params) do
    case Authentication.authenticate(conn, params) do
      {:ok, conn} ->
        # do stuff
        redirect(conn, to: "/")

      {:error, _reason, conn} ->
        redirect(conn, to: "/error")
    end
  end

  def authorize(conn, _params) do
    redirect(conn, external: Authorization.url())
  end
end
