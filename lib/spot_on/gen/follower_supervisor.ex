defmodule SpotOn.Gen.FollowerSupervisor do
  use DynamicSupervisor
  alias SpotOn.Model
  alias SpotOn.Gen.PlayingTrackFollower
  require Logger

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_all_follows() do
    Model.list_follows() |> Enum.each(fn follow ->
      start_follow(follow.leader_user.name, follow.follower_user.name)
    end)
  end

  def start_follow(leader_name, follower_name) do
    state = PlayingTrackFollower.new(leader_name, follower_name)

    DynamicSupervisor.start_child(__MODULE__, %{
      id: {:global, state},
      start: {PlayingTrackFollower, :start_link, [state]},
      restart: :transient
    })
  end

  def stop_all_follows() do
    Model.list_follows() |> Enum.each(fn follow ->
      stop_follow(follow.leader_user.name, follow.follower_user.name)
    end)
  end

  def stop_follow(leader_name, follower_name) do
    :global.whereis_name(PlayingTrackFollower.new(leader_name, follower_name))
    |> stop_follow()
  end

  def stop_follow(:undefined), do: nil

  def stop_follow(pid) when is_pid(pid) do
    pid
    |> Process.exit(:ok)
  end

end
