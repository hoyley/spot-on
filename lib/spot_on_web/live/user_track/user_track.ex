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

  @playing_track_progress_tick_ms 20
  @type display_mode ::
          :full
          | :simple

  def mount(
        _params,
        %{
          "user_name" => user_name,
          "logged_in_user_name" => logged_in_user_name,
          "spotify_access_token" => spotify_access_token,
          "spotify_refresh_token" => spotify_refresh_token,
          "display_mode" => display_mode
        },
        socket
      ) do
    credentials = Credentials.new(spotify_access_token, spotify_refresh_token)
    SpotOn.PubSub.subscribe_playing_track_update_by_user_name(user_name)
    SpotOn.PubSub.subscribe_follow_update_leader(user_name)
    SpotOn.PubSub.subscribe_follow_update_follower(user_name)
    SpotOn.PubSub.subscribe_user_update(user_name)

    card_user = Model.get_user_by_name(user_name)
    schedule_tick()

    {:ok,
     socket
     |> assign_follows(card_user, logged_in_user_name)
     |> assign_playing_track(card_user)
     |> assign(:spotify_credentials, credentials)
     |> assign(:display_mode, display_mode)}
  end

  def render(assigns = %{display_mode: :simple}), do: SpotOnWeb.UserTrackSimple.render(assigns)

  def render(assigns = %{display_mode: :full}), do: SpotOnWeb.UserTrackFull.render(assigns)

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
    do: {:noreply, socket |> handle_tick}

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
             card_user: %User{} = user,
             logged_in_user_name: logged_in_user_name
           }
         }
       ),
       do: assign_follows(socket, user, logged_in_user_name)

  defp assign_follows(socket, card_user = %User{}, logged_in_user_name) do
    card_user_follow = Model.get_follow_by_follower_name(card_user.name)
    logged_in_user_follow = Model.get_follow_by_follower_name(logged_in_user_name)

    logged_in_user_leader = logged_in_user_follow && logged_in_user_follow.leader_user
    card_user_leader = card_user_follow && card_user_follow.leader_user

    socket
    |> assign(:card_user, card_user)
    |> assign(:card_user_leader, card_user_leader)
    |> assign(:logged_in_user_name, logged_in_user_name)
    |> assign(:logged_in_user_leader, logged_in_user_leader)
  end

  def assign_playing_track(socket, %User{status: :revoked}), do: assign_playing_track(socket, nil)

  def assign_playing_track(socket, %User{status: :active, name: name}),
    do: assign_playing_track(socket, PlayingTrackSync.get(name))

  def assign_playing_track(socket, nil), do: assign_playing_track(socket, nil, nil)

  def assign_playing_track(socket, track = %PlayingTrack{}),
    do: assign_playing_track(socket, track, DateTime.utc_now())

  def assign_playing_track(socket, nil, _),
    do:
      socket
      |> assign(:playing_track, nil)
      |> assign(:estimated_track, nil)
      |> assign(:playing_track_updated, nil)

  def assign_playing_track(socket, track = %PlayingTrack{}, nil),
    do: assign_playing_track(socket, track, DateTime.utc_now())

  def assign_playing_track(
        socket,
        track = %PlayingTrack{},
        last_updated = %DateTime{}
      ) do
    socket
    |> assign(:playing_track, track)
    |> assign(:estimated_track, get_estimated_track(track, last_updated, 0))
    |> assign(:playing_track_updated, last_updated)
  end

  def handle_tick(
        socket = %{
          assigns: %{playing_track: track, playing_track_updated: updated_at}
        }
      ) do
    schedule_tick()

    socket
    |> assign(:estimated_track, track && get_estimated_track(track, updated_at, 0))
  end

  def terminate(reason, socket) do
    IO.inspect(reason)
    {:noreply, socket}
  end

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

  defp schedule_tick(),
    do:
      Process.send_after(
        self(),
        :playing_track_progress_tick,
        @playing_track_progress_tick_ms
      )
end
