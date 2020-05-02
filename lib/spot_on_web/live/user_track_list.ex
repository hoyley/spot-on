defmodule SpotOnWeb.UserTrackList do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias SpotOn.Actions
  alias SpotOn.Model
  alias SpotOn.Model.User
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOnWeb.Router.Helpers, as: Routes
  require Logger

  def mount(
        _params,
        _session = %{
          "logged_in_user_name" => user_name,
          "spotify_access_token" => access_token,
          "spotify_refresh_token" => refresh_token
        },
        socket
      ) do
    logged_in_user = Model.get_user_by_name(user_name)

    all_users =
      Actions.get_all_users()
      |> Enum.sort(sort_function(logged_in_user))

    Model.update_user_last_login(logged_in_user)

    {:ok,
     socket
     |> assign(
       :spotify_credentials,
       Credentials.new(access_token, refresh_token)
     )
     |> assign(:logged_in_user, logged_in_user)
     |> assign(:users, all_users)}
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> redirect(to: Routes.page_path(socket, :index))}
  end

  def sort_function(logged_in_user = %User{}) do
    fn user1, user2 ->
      user1_date =
        max(DateTime.to_unix(user1.last_login), DateTime.to_unix(user1.last_spotify_activity))

      user2_date =
        max(DateTime.to_unix(user2.last_login), DateTime.to_unix(user2.last_spotify_activity))

      cond do
        user1 === user2 -> true
        user1.id === logged_in_user.id -> true
        user2.id === logged_in_user.id -> false
        user1_date >= user2_date -> true
        true -> false
      end
    end
  end
end
