defmodule SpotOn.Gen.DbWorker do
  use GenServer
  alias SpotOn.Model
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(state) do
    SpotOn.PubSub.subscribe_playing_track_update()

    {:ok, state}
  end

  @impl true
  def handle_info({:update_playing_track, user_name, _}, state) do
    update_spotify_activity(user_name)
    {:noreply, state}
  end

  defp update_spotify_activity(user_name) do
    try do
      {:ok, user} = Model.get_user_by_name(user_name)
        |> Model.update_user_last_spotify_activity

      user |> SpotOn.PubSub.publish_user_update
    rescue
      error -> Logger.error Exception.format(:error, error, __STACKTRACE__)
               raise error
    end
  end
end