defmodule SpotOnWeb.UserTrack do
  use Phoenix.LiveView
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.Model.User
  alias SpotOn.Model
  alias SpotOn.Actions
  alias SpotOn.Gen.PlayingTrackSync
  require Logger

  def mount(_params, %{
    "user_name" => user_name,
    "logged_in_user_name" => logged_in_user_name,
    "spotify_access_token" => spotify_access_token,
    "spotify_refresh_token" => spotify_refresh_token},
    socket) do

    Phoenix.PubSub.subscribe(:spot_on, "playing_track_update:#{user_name}")
    Phoenix.PubSub.subscribe(:spot_on, "live_user_track_follow_update:#{user_name}")

    {:ok, socket
    |> assign(:playing_track, PlayingTrackSync.get(user_name))
    |> assign(:spotify_credentials, Credentials.new(spotify_access_token, spotify_refresh_token))
    |> assign_follows(user_name, logged_in_user_name)}
  end

  def handle_info({:update_playing_track, track}, socket) do
    {:noreply, assign(socket, :playing_track, track)}
  end

  def handle_info({:follow_update, publisher_pid}, socket) when publisher_pid == self() do
    {:noreply, socket}
  end

  def handle_info({:follow_update, _publisher_pid}, socket) do
    {:noreply, assign_follows(socket)}
  end

  def handle_info({:follow, leader_name}, socket = %{assigns: %{spotify_credentials: creds = %Credentials{}}}), do:
    do_follow(socket, leader_name, creds)

  def handle_info({:unfollow, leader_name}, socket = %{assigns: %{spotify_credentials: creds = %Credentials{}}}), do:
    do_unfollow(socket, leader_name, creds)

  defp assign_follows(socket = %{assigns: %{
    user: %User{name: user_name},
    logged_in_user_name: logged_in_user_name}}), do:
    assign_follows(socket, user_name, logged_in_user_name)

  defp assign_follows(socket, user_name, logged_in_user_name) do
    user = Model.get_user_by_name(user_name)
    follow = Model.get_follow_by_follower_name(user_name)
    users_current_leader = follow && follow.leader_user

    logged_in_user_follow = Model.get_follow_by_follower_name(logged_in_user_name)
    logged_in_user_leader = logged_in_user_follow && logged_in_user_follow.leader_user

    # Only allow the logged in user to follow the given user if logged_in_user currently doesn't
    # have a leader, or if logged_in_user's leader is not the given user. We don't want a circular reference.
    logged_in_user_can_follow = logged_in_user_name !== user.name &&
      (logged_in_user_leader == nil || logged_in_user_leader.name !== user.name) &&
      (users_current_leader == nil || users_current_leader.name !== logged_in_user_name)

    logged_in_user_can_unfollow = (logged_in_user_leader != nil && logged_in_user_name === user.name)

    socket
    |> assign(:user, user)
    |> assign(:leader, users_current_leader)
    |> assign(:logged_in_user_name, logged_in_user_name)
    |> assign(:logged_in_user_leader, logged_in_user_leader)
    |> assign(:logged_in_user_can_follow, logged_in_user_can_follow)
    |> assign(:logged_in_user_can_unfollow, logged_in_user_can_unfollow)
  end

  defp do_follow(socket, leader_name, creds = %Credentials{}) do
    follow = Actions.start_follow(creds, leader_name)
    publish_follow_update(follow.follower_name)
    publish_follow_update(follow.leader_name)
    {:noreply, socket
      |> assign_follows
      |> assign(:spotify_credentials, creds)
    }
  end

  defp do_unfollow(socket, leader_name, creds = %Credentials{}) do
    follow = Actions.stop_follow(creds, leader_name)
    publish_follow_update(follow.follower_name)
    publish_follow_update(follow.leader_name)
    {:noreply, socket
      |> assign_follows
      |> assign(:spotify_credentials, creds)
    }
  end

  defp publish_follow_update(leader_name) do
    Phoenix.PubSub.broadcast(:spot_on, "live_user_track_follow_update:#{leader_name}", {:follow_update, self()})
  end
end
