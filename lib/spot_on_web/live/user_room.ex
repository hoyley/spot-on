defmodule SpotOnWeb.UserRoom do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  alias SpotOn.Model
  alias SpotOn.Model.User
  alias SpotOn.Model.Follow
  alias SpotOn.Actions
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOnWeb.Router.Helpers, as: Routes

  def mount(
        _params,
        _session = %{
          "logged_in_user_name" => logged_in_user_name,
          "spotify_access_token" => access_token,
          "spotify_refresh_token" => refresh_token
        },
        socket
      ) do
    SpotOn.PubSub.subscribe_follow_update()

    {:ok,
     socket
     |> assign(:spotify_credentials, Credentials.new(access_token, refresh_token))
     |> assign(:logged_in_user_name, logged_in_user_name)}
  end

  def mount(
        _params,
        _session,
        socket
      ) do
    {:ok, socket |> redirect_to_auth}
  end

  def handle_params(
        %{"user_name" => room_user_name},
        _uri,
        socket = %{
          assigns: %{
            spotify_credentials: credentials
          }
        }
      ) do
    %{result: logged_in_user, credentials: new_creds} = Actions.get_my_user(credentials)
    room_user = Model.get_user_by_name(room_user_name)

    {:noreply,
     socket
     |> assign(:spotify_credentials, new_creds)
     |> assign_room_user(room_user)
     |> assign_logged_in_user(logged_in_user)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket |> redirect_to_auth}

  defp assign_logged_in_user(socket, nil), do: socket |> redirect_to_auth

  defp assign_logged_in_user(socket, logged_in_user = %User{}),
    do: socket |> assign(:logged_in_user, logged_in_user)

  defp assign_room_user(socket, room_user = %User{}) do
    followers = Actions.get_following_users(room_user.name)

    socket
    |> assign(:room_user, room_user)
    |> assign(:followers, followers)
  end

  defp assign_room_user(_socket, nil), do: raise("User not found")

  def handle_info(
        {:follow_update, changed_follow = %Follow{}},
        socket = %{
          assigns: %{
            followers: followers,
            room_user: room_user
          }
        }
      ) do
    any_follower_update = followers |> Enum.any?(&(&1.name === changed_follow.follower_user.name))
    leader_update = changed_follow.leader_user.name == room_user.name

    case any_follower_update || leader_update do
      true -> {:noreply, socket |> assign_room_user(room_user)}
      false -> {:noreply, socket}
    end
  end

  defp redirect_to_auth(socket),
    do: socket |> redirect(to: "#{Routes.auth_path(socket, :authorize)}?origin=/home")
end
