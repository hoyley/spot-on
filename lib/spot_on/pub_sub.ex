defmodule SpotOn.PubSub do
  alias SpotOn.Model.Follow
  alias SpotOn.Model.User

  def publish_playing_track_update(user_name, playing_track) do
    Phoenix.PubSub.broadcast(
      :spot_on,
      "playing_track_update:*",
      {:update_playing_track, user_name, playing_track}
    )

    Phoenix.PubSub.broadcast(
      :spot_on,
      "playing_track_update:#{user_name}",
      {:update_playing_track, user_name, playing_track}
    )
  end

  def subscribe_playing_track_update() do
    Phoenix.PubSub.subscribe(:spot_on, "playing_track_update:*")
  end

  def subscribe_playing_track_update_by_user_name(user_name) do
    Phoenix.PubSub.subscribe(:spot_on, "playing_track_update:#{user_name}")
  end

  def publish_follow_update_follower(user_name) do
    Phoenix.PubSub.broadcast(
      :spot_on,
      "follow_update_follower:#{user_name}",
      :follow_update_leader
    )
  end

  def publish_follow_update(follow = %Follow{}) do
    Phoenix.PubSub.broadcast(
      :spot_on,
      "follow_update:*",
      {:follow_update, follow}
    )

    Phoenix.PubSub.broadcast(
      :spot_on,
      "follow_update_leader:#{follow.leader_user.name}",
      {:follow_update_leader, follow}
    )

    Phoenix.PubSub.broadcast(
      :spot_on,
      "follow_update_follower:#{follow.follower_user.name}",
      {:follow_update_leader, follow}
    )
  end

  def subscribe_follow_update() do
    Phoenix.PubSub.subscribe(:spot_on, "follow_update:*")
  end

  def subscribe_follow_update_leader(user_name) do
    Phoenix.PubSub.subscribe(:spot_on, "follow_update_leader:#{user_name}")
  end

  def subscribe_follow_update_follower(user_name) do
    Phoenix.PubSub.subscribe(:spot_on, "follow_update_follower:#{user_name}")
  end

  def publish_user_update(user = %User{}) do
    Phoenix.PubSub.broadcast(:spot_on, "user_update:*", {:user_update, user})

    Phoenix.PubSub.broadcast(
      :spot_on,
      "user_update:#{user.name}",
      {:user_update, user}
    )
  end

  def subscribe_user_update() do
    Phoenix.PubSub.subscribe(:spot_on, "user_update:*")
  end

  def subscribe_user_update(user_name) do
    Phoenix.PubSub.subscribe(:spot_on, "user_update:#{user_name}")
  end

  def publish_user_revoke_refresh_token(user_name) do
    Phoenix.PubSub.broadcast(:spot_on, "user_revoke_refresh_token:#{user.name}", {:user_revoke_refresh_token, user_name})
  end

  def subscribe_user_revoke_refresh_token(user_name) do
    Phoenix.PubSub.subscribe(:spot_on, "user_revoke_refresh_token:#{user_name}")
  end
end
