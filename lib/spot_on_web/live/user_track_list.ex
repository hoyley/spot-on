defmodule SpotOnWeb.UserTrackList do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias SpotOn.Actions
  alias SpotOn.Model
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOnWeb.Router.Helpers, as: Routes
  require Logger

  def mount(_params, _session = %{
      "logged_in_user_name" => user_name,
      "spotify_access_token" => access_token,
      "spotify_refresh_token" => refresh_token}, socket) do

    logged_in_user = Model.get_user_by_name(user_name)
    all_users = Actions.get_all_users()

    Model.update_user_last_login(logged_in_user)

    {:ok, socket
          |> assign(:spotify_credentials, Credentials.new(access_token, refresh_token))
          |> assign(:logged_in_user, logged_in_user)
          |> assign(:users, all_users)}
  end

  def mount(_params, _session, socket) do
    {:ok,  socket
      |> redirect(to: Routes.page_path(socket, :index))
    }
  end

end
