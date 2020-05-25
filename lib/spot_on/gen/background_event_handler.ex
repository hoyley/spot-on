defmodule SpotOn.Gen.BackgroundEventHandler do
  use GenServer
  alias SpotOn.Model
  alias SpotOn.Actions
  alias SpotOn.Gen.PlayingTrackFollower
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(state) do
    SpotOn.PubSub.subscribe_playing_track_update()
    SpotOn.PubSub.subscribe_user_revoke_refresh_token()
    SpotOn.PubSub.subscribe_follow_state()
    {:ok, state}
  end

  @impl true
  def handle_info({:update_playing_track, user_name, _}, state) do
    update_spotify_activity(user_name)
    {:noreply, state}
  end

  def handle_info({:user_revoke_refresh_token, user_name}, state) do
    revoke_refresh_token(user_name)
    {:noreply, state}
  end

  def handle_info({:update_playing_track, user_name}, state) do
    revoke_refresh_token(user_name)
    {:noreply, state}
  end

  def handle_info(
        {:follow_state_update,
         follow_state = %PlayingTrackFollower{
           state: :follower_inactive,
           previous_state: previous_state
         }},
        state
      )
      when previous_state != :follow_initiated do
    follow_state |> log
    Actions.stop_follow(follow_state.leader_name, follow_state.follower_name)
    {:noreply, state}
  end

  def handle_info({:follow_state_update, follow_state = %PlayingTrackFollower{}}, state) do
    follow_state |> log
    {:noreply, state}
  end

  defp update_spotify_activity(user_name) do
    try do
      {:ok, user} =
        Model.get_user_by_name(user_name)
        |> Model.update_user_last_spotify_activity()

      user |> SpotOn.PubSub.publish_user_update()
    rescue
      error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        raise error
    end
  end

  defp revoke_refresh_token(user_name) do
    try do
      {:ok, user} =
        Model.get_user_by_name(user_name)
        |> Model.update_user(%{status: :revoked})

      user |> SpotOn.PubSub.publish_user_update()
    rescue
      error ->
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        raise error
    end
  end

  defp log(state = %PlayingTrackFollower{}),
    do:
      Logger.info(
        "FollowStateUpdate -- #{state.follower_name} | #{state.leader_name} | #{state.state} (follower | leader | state)"
      )
end
