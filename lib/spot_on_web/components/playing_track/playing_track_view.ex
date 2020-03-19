defmodule SpotOnWeb.Components.PlayingTrackView do
  alias SpotOnWeb.Components.ComponentHelpers
  use SpotOnWeb, {:view, ComponentHelpers.view_opts(:playing_track)}

  def get_leader(follow_map, follower) do
    follow_map
    |> Map.get(follower)
  end

end
