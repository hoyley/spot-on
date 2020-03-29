defmodule SpotOnWeb.UserTrack do
  use Phoenix.LiveView
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  alias SpotOn.Model.User
  alias SpotOn.Model
  alias SpotOn.Actions
  alias SpotOn.Gen.PlayingTrackSync
  import SpotOn.Helpers.EstimatedTrack
  require Logger

  @playing_track_progress_tick_ms 1000

  def mount(
        _params,
        %{
          "user_name" => user_name,
          "logged_in_user_name" => logged_in_user_name,
          "spotify_access_token" => spotify_access_token,
          "spotify_refresh_token" => spotify_refresh_token
        },
        socket
      ) do
    SpotOn.PubSub.subscribe_playing_track_update_by_user_name(user_name)
    SpotOn.PubSub.subscribe_follow_update_leader(user_name)
    SpotOn.PubSub.subscribe_follow_update_follower(user_name)
    SpotOn.PubSub.subscribe_user_update(user_name)

    {:ok,
     socket
     |> assign_playing_track(PlayingTrackSync.get(user_name))
     |> assign(
       :spotify_credentials,
       Credentials.new(spotify_access_token, spotify_refresh_token)
     )
     |> assign_follows(user_name, logged_in_user_name)}
  end

  def handle_info({:update_playing_track, _user_name, track}, socket) do
    {:noreply, socket |> assign_playing_track(track)}
  end

  def handle_info({:follow_update_leader, _}, socket),
    do: {:noreply, assign_follows(socket)}

  def handle_info({:follow_update_follower, _}, socket),
    do: {:noreply, assign_follows(socket)}

  def handle_info({:user_update, _}, socket),
    do: {:noreply, assign_follows(socket)}

  def handle_info(:playing_track_progress_tick, socket),
    do: {:noreply, socket |> assign_playing_track}

  def handle_info(
        {:follow, leader_name},
        socket = %{assigns: %{spotify_credentials: creds = %Credentials{}}}
      ),
      do: do_follow(socket, leader_name, creds)

  def handle_info(
        {:unfollow, leader_name},
        socket = %{assigns: %{spotify_credentials: creds = %Credentials{}}}
      ),
      do: do_unfollow(socket, leader_name, creds)

  defp assign_follows(
         socket = %{
           assigns: %{
             user: %User{name: user_name},
             logged_in_user_name: logged_in_user_name
           }
         }
       ),
       do: assign_follows(socket, user_name, logged_in_user_name)

  defp assign_follows(socket, user_name, logged_in_user_name) do
    user = Model.get_user_by_name(user_name)
    follow = Model.get_follow_by_follower_name(user_name)
    users_current_leader = follow && follow.leader_user

    logged_in_user_follow = Model.get_follow_by_follower_name(logged_in_user_name)

    logged_in_user_leader = logged_in_user_follow && logged_in_user_follow.leader_user

    # Only allow the logged in user to follow the given user if logged_in_user currently doesn't
    # have a leader, or if logged_in_user's leader is not the given user. We don't want a circular reference.
    logged_in_user_can_follow =
      logged_in_user_name !== user.name &&
        (logged_in_user_leader == nil ||
           logged_in_user_leader.name !== user.name) &&
        (users_current_leader == nil ||
           users_current_leader.name !== logged_in_user_name)

    logged_in_user_can_unfollow = logged_in_user_leader != nil && logged_in_user_name === user.name

    socket
    |> assign(:user, user)
    |> assign(:leader, users_current_leader)
    |> assign(:logged_in_user_name, logged_in_user_name)
    |> assign(:logged_in_user_leader, logged_in_user_leader)
    |> assign(:logged_in_user_can_follow, logged_in_user_can_follow)
    |> assign(:logged_in_user_can_unfollow, logged_in_user_can_unfollow)
  end

  def assign_playing_track(socket, track = %PlayingTrack{}),
    do: assign_playing_track(socket, track, DateTime.utc_now())

  def assign_playing_track(socket, nil),
    do:
      socket
      |> assign(:playing_track, nil)
      |> assign(:estimated_track, nil)
      |> assign(:playing_track_updated, nil)

  def assign_playing_track(
        socket,
        track = %PlayingTrack{},
        last_updated = %DateTime{}
      ) do
    estimated_track = track && get_estimated_track(track, last_updated)

    estimated_track && estimated_track.is_playing &&
      Process.send_after(
        self(),
        :playing_track_progress_tick,
        @playing_track_progress_tick_ms
      )

    socket
    |> assign(:playing_track, track)
    |> assign(:estimated_track, estimated_track)
    |> assign(:playing_track_updated, last_updated)
  end

  def assign_playing_track(
        socket = %{
          assigns: %{playing_track: track, playing_track_updated: updated_at}
        }
      ),
      do: assign_playing_track(socket, track, updated_at)

  defp do_follow(socket, leader_name, creds = %Credentials{}) do
    %{credentials: new_creds} = Actions.start_follow(creds, leader_name)

    {:noreply,
     socket
     |> assign_follows
     |> assign(:spotify_credentials, new_creds)}
  end

  defp do_unfollow(socket, leader_name, creds = %Credentials{}) do
    %{credentials: new_creds} = Actions.stop_follow(creds, leader_name)

    {:noreply,
     socket
     |> assign_follows
     |> assign(:spotify_credentials, new_creds)}
  end
end
