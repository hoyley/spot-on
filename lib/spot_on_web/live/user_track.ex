defmodule SpotOnWeb.UserTrack do
  use Phoenix.LiveView
  alias SpotOn.Model
  alias SpotOn.Gen.PlayingTrackSync

  def mount(_params, %{
    "user_name" => user_name,
    "logged_in_user_name" => logged_in_user_name},
    socket) do

    Phoenix.PubSub.subscribe(:playing_track, "playing_track_update:#{user_name}")

    playing_track = PlayingTrackSync.get(user_name)
    user = Model.get_user_by_name(user_name)
    follow = Model.get_follow_by_follower_name(user_name)
    leader = follow && follow.leader_user

    logged_in_user_follow = Model.get_follow_by_follower_name(logged_in_user_name)
    logged_in_user_leader = logged_in_user_follow && logged_in_user_follow.leader_user

    new_socket = socket
    |> assign(:playing_track, playing_track)
    |> assign(:user, user)
    |> assign(:leader, leader)
    |> assign(:logged_in_user_name, logged_in_user_name)
    |> assign(:logged_in_user_leader, logged_in_user_leader)

    {:ok, new_socket}
  end

  def handle_info({:update, track}, socket) do
    new_socket = socket
      |> assign(:playing_track, track)

    {:noreply, new_socket}
  end

end
