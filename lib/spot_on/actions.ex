defmodule SpotOn.Actions do
  alias SpotOn.Model
  alias SpotOn.Gen.FollowerSupervisor
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.Profile
  alias SpotOn.SpotifyApi.Cookies
  alias SpotOn.Model.User
  require Logger

  def get_my_user(conn = %Credentials{}) do
    %ApiSuccess{result: profile} = Api.get_my_profile(conn)
    Model.get_user_by_name(profile.id)
  end

  def get_credentials_by_user_id(user_id) do
    Model.get_user_token_by_user_name(user_id)
    |> Credentials.new()
  end

  def get_all_users() do
    Model.list_spotify_users()
  end

  def get_playing_track(user_id) when is_binary(user_id) do
    SpotOn.Gen.PlayingTrackSync.get(user_id)
  end

  def get_following_users(leader_user_name) do
    Model.list_follows()
    |> Enum.filter(&(&1.leader_user.name === leader_user_name))
    |> Enum.map(& &1.follower_user)
  end

  def start_follow(creds = %Credentials{}, leader = %User{}, follower = %User{}) do
    existing_follow = Model.get_follow(leader.name, follower.name)
    existing_follow && Model.delete_follow(existing_follow)

    {:ok, follow} =
      Model.create_follow(%{
        leader_user_id: leader.id,
        follower_user_id: follower.id
      })

    follow
    |> Map.get(:id)
    |> Model.get_follow!()
    |> SpotOn.PubSub.publish_follow_update()

    FollowerSupervisor.start_follow(leader.name, follower.name)

    %{
      follower_name: follower.name,
      leader_name: leader.name,
      credentials: creds
    }
  end

  def start_follow(%Credentials{}, leader_name, follower_name)
      when leader_name === follower_name,
      do: nil

  def start_follow(creds = %Credentials{}, leader_name, follower_name) do
    leader = Model.get_user_by_name(leader_name)
    follower = Model.get_user_by_name(follower_name)

    creds |> start_follow(leader, follower)
  end

  def start_follow(conn = %Credentials{}, leader_name) do
    %ApiSuccess{result: profile, credentials: creds} = Api.get_my_profile(conn)
    follower_name = profile.id

    creds |> start_follow(leader_name, follower_name)
  end

  def stop_follow(conn = %Credentials{}, leader_name)
      when leader_name !== nil do
    %ApiSuccess{result: profile, credentials: creds} = Api.get_my_profile(conn)
    follower_name = profile.id
    stop_follow(creds, leader_name, follower_name)
  end

  def stop_follow(leader_name, follower_name) do
    creds = get_credentials_by_user_id(follower_name)
    stop_follow(creds, leader_name, follower_name)
  end

  def stop_follow(creds = %Credentials{}, leader_name, follower_name) do
    follow = Model.get_follow(leader_name, follower_name)

    follow && Model.delete_follow(follow) &&
      SpotOn.PubSub.publish_follow_update(follow)

    FollowerSupervisor.stop_follow(leader_name, follower_name)

    %{
      follower_name: follower_name,
      leader_name: leader_name,
      credentials: creds
    }
  end

  def stop_follow(follower_name) do
    follow = Model.get_follow_by_follower_name(follower_name)
    follow && stop_follow(follow.leader_user.name, follow.follower_user.name)
  end

  def update_my_user_tokens(conn = %Plug.Conn{}) do
    %ApiSuccess{credentials: new_creds} =
      conn
      |> Credentials.new()
      |> update_my_user_tokens()

    Cookies.set_cookies(conn, new_creds)
  end

  def update_my_user_tokens(creds = %Credentials{}) do
    creds
    |> Api.call(&Profile.me/1)
    |> handle_update_user_tokens()
  end

  def update_user_tokens(creds = %Credentials{}, user_name) do
    user_call = fn credentials -> Profile.user(credentials, user_name) end

    creds
    |> Api.call(user_call / 1)
    |> handle_update_user_tokens()
  end

  defp handle_update_user_tokens(
         success = %ApiSuccess{
           result: %Profile{id: spotify_id, display_name: display_name},
           credentials: credentials
         }
       ) do
    {:ok, user = %User{}} =
      Model.create_or_update_user(%{
        name: spotify_id,
        display_name: display_name,
        status: :active
      })

    user
    |> Model.create_or_update_user_tokens(credentials)

    success
  end
end
