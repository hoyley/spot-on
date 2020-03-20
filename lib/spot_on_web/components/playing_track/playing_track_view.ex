defmodule SpotOnWeb.Components.PlayingTrackView do
  alias SpotOnWeb.Components.ComponentHelpers
  alias SpotOnWeb.Models.PageModel
  alias SpotOn.Model.User

  use SpotOnWeb, {:view, ComponentHelpers.view_opts(:playing_track)}

  def get_leader(page_model = %PageModel{}, follower = %User{}) do
    leader_name = page_model.follow_map
    |> Map.get(follower.name)

    page_model.users |> Enum.find(fn user -> user.name == leader_name end)
  end

  def logged_in_user_can_unfollow(page_model, follower) do
    page_model.logged_in_user == follower
  end

  def logged_in_user_can_follow(page_model, user) do
    follower_name = page_model.logged_in_user.name
    leader_name = user.name
    follower_name != leader_name
      && !Map.has_key?(page_model.follow_map, follower_name)
      && Map.get(page_model.follow_map, leader_name) != follower_name
  end

  def get_playing_track(page_model = %PageModel{}, user = %User{}) do
    page_model.playing_tracks |> Enum.find(fn playing_track ->
      playing_track.user_name === user.name
    end)
  end
end
