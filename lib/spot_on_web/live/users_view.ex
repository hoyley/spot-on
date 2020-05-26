defmodule SpotOnWeb.UsersView do
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
          "spotify_access_token" => access_token,
          "spotify_refresh_token" => refresh_token
        },
        socket
      ) do
    creds = Credentials.new(access_token, refresh_token)
    %{result: logged_in_user, credentials: new_creds} = Actions.get_my_user(creds)

    {:ok,
     socket
     |> assign(:spotify_credentials, new_creds)
     |> assign_user(logged_in_user)}
  end

  def mount(_params, _session, socket), do: {:ok, socket |> redirect_to_auth}

  defp assign_user(socket, logged_in_user = %User{}) do
    all_users =
      Actions.get_all_users()
      |> Enum.sort(sort_function(logged_in_user))

    Model.update_user_last_login(logged_in_user)

    socket
    |> assign(:logged_in_user, logged_in_user)
    |> assign(:users, all_users)
  end

  defp assign_user(socket, nil), do: {:ok, socket |> redirect_to_auth}

  defp redirect_to_auth(socket),
    do: socket |> redirect(to: "#{Routes.auth_path(socket, :authorize)}?origin=/users")

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
