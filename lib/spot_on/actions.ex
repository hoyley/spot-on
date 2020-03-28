defmodule SpotOn.Actions do
  alias SpotOn.Model
  alias SpotOn.Gen.FollowerSupervisor
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Credentials
  require Logger

  def get_my_user(conn = %Credentials{}) do
    %ApiSuccess{result: profile} = Api.get_my_profile(conn)
    Model.get_user_by_name(profile.id)
  end

  def get_credentials_by_user_id(user_id) do
    Model.get_user_token_by_user_name(user_id)
    |> Credentials.new
  end

  def get_all_playing_tracks() do
    Model.list_spotify_users()
      |> (Enum.map fn user -> get_playing_track(user.name) end)
      |> Enum.reject(&is_nil/1)
  end

  def get_all_users() do
    Model.list_spotify_users()
  end

  def get_playing_track(user_id) when is_binary(user_id) do
    SpotOn.Gen.PlayingTrackSync.get(user_id)
  end

  def start_follow(conn = %Credentials{}, leader_name) do
    %ApiSuccess{result: profile, credentials: creds} = Api.get_my_profile(conn)
    follower_name = profile.id

    leader = Model.get_user_by_name(leader_name)
    follower = Model.get_user_by_name(follower_name)
    {:ok, follow} = Model.create_follow(%{leader_user_id: leader.id, follower_user_id: follower.id})
    follow
    |> Map.get(:id)
    |> Model.get_follow!
    |> SpotOn.PubSub.publish_follow_update

    FollowerSupervisor.start_follow(leader_name, follower_name)

    %{follower_name: follower_name, leader_name: leader_name, credentials: creds}
  end

  def stop_follow(conn = %Credentials{}, leader_name) when leader_name !== nil do
    %ApiSuccess{result: profile, credentials: creds} = Api.get_my_profile(conn)
    follower_name = profile.id

    follow = Model.get_follow(leader_name, follower_name)
    follow && Model.delete_follow(follow) && SpotOn.PubSub.publish_follow_update(follow)

    FollowerSupervisor.stop_follow(leader_name, follower_name)


    %{follower_name: follower_name, leader_name: leader_name, credentials: creds}
  end
end
