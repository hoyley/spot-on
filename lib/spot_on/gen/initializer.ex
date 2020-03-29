defmodule SpotOn.Gen.Initializer do
  use GenServer
  alias SpotOn.Gen.FollowerSupervisor

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(state) do
    FollowerSupervisor.start_all_follows()

    {:ok, state}
  end
end
