defmodule SpotOn.Actions do
  alias SpotOn.Model
  alias SpotOn.Gen.FollowerSupervisor
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.PlayingTrack
  require Logger

  def get_my_profile(conn = %Credentials{}) do
    Api.get_my_profile(conn)
  end

  def get_credentials_by_user_id(user_id) do
    Model.get_user_token_by_user_name(user_id)
    |> Credentials.new
  end

  def get_all_users_playing_tracks() do
    Model.list_spotify_users()
      |> (Enum.map fn user ->
        get_playing_track(user.name)
      end) || []
  end

  def get_playing_track(user_id) when is_binary(user_id) do
    SpotOn.Gen.PlayingTrackSync.get(user_id)
    || PlayingTrack.new(user_id)
  end

  def start_follow(conn = %Credentials{}, leader_name) do
    %ApiSuccess{result: profile} = get_my_profile(conn)
    follower_name = profile.id

    leader = Model.get_user_by_name(leader_name)
    follower = Model.get_user_by_name(follower_name)
    Model.create_follow(%{leader_user_id: leader.id, follower_user_id: follower.id})
    FollowerSupervisor.start_follow(leader_name, follower_name)
  end

  def stop_follow(leader_name, follower_name) do
    Model.delete_follow(Model.get_follow(leader_name, follower_name))
    FollowerSupervisor.stop_follow(leader_name, follower_name)
  end

  def get_follow_map() do
    Model.list_follows() |> Enum.reduce(%{}, fn (follows, map) ->
      Map.put(map, follows.follower_user.name, follows.leader_user.name)
    end)
  end
end
