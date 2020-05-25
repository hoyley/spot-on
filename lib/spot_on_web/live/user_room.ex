defmodule SpotOnWeb.UserRoom do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  alias SpotOn.Model
  alias SpotOn.Model.User
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
    {:ok,
     socket
     |> assign(
       :spotify_credentials,
       Credentials.new(access_token, refresh_token)
     )
     |> assign(:logged_in_user_name, logged_in_user_name)}
  end

  def mount(
        _params,
        _session,
        socket
      ) do
    {:ok, socket}
  end

  def handle_params(
        params,
        _uri,
        socket = %{
          assigns: %{
            spotify_credentials: creds,
            logged_in_user_name: logged_in_user_name
          }
        }
      ) do
    room_user_name = params["user_name"]
    room_user = Model.get_user_by_name(room_user_name)
    logged_in_user = Model.get_user_by_name(logged_in_user_name)

    Actions.start_follow(creds, room_user_name)

    {:noreply,
     socket
     |> assign_room_user(room_user)
     |> assign(:logged_in_user, logged_in_user)}
  end

  def handle_params(_params, uri, socket) do
    path = URI.parse(uri).path

    {:noreply,
     socket
     |> redirect(to: "#{Routes.auth_path(socket, :authorize)}?origin=#{path}")}
  end

  def assign_room_user(_socket, nil) do
    raise "User not found"
  end

  def assign_room_user(socket, room_user = %User{}) do
    followers = Actions.get_following_users(room_user.name)

    socket
    |> assign(:room_user, room_user)
    |> assign(:followers, followers)
  end
end
