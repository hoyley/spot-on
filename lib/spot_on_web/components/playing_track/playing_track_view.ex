defmodule SpotOnWeb.Components.PlayingTrackView do
  alias SpotOnWeb.Components.ComponentHelpers
  use SpotOnWeb, {:view, ComponentHelpers.view_opts(:playing_track)}

  def logged_in_user_name(conn) do
    conn.assigns[:logged_in_user_name]
  end

  def follow_map(conn) do
    conn.assigns[:follow_map]
  end

  def get_leader(follow_map, follower) do
    follow_map
    |> Map.get(follower)
  end

  def can_follow(conn, user_name) do
    logged_in_user = logged_in_user_name(conn)
    user_name !== logged_in_user
      && !Map.has_key?(follow_map(conn), logged_in_user)
  end
end
