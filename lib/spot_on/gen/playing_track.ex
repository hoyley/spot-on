defmodule SpotOn.Gen.PlayingTrack do
  use GenServer
  alias SpotOn.SpotifyApi.Api
  alias SpotOn.SpotifyApi.Credentials
  require Logger

  def start_link(user_id, creds = %Credentials{}) do
    GenServer.start_link(__MODULE__, {user_id, nil, creds}, name: {:global, user_id})
  end

  def get(user_id) do
    GenServer.call({:global, user_id}, :get)
  end

  @impl true
  def init(state) do
    try do
      {user_id, _, _} = state
      new_state = get_playing_track(state)
      Logger.debug 'Started GenServer for PlayingTrack[#{user_id}]'

      schedule_get()
      {:ok, new_state}
    rescue
      error -> Logger.error Exception.format(:error, error, __STACKTRACE__)
               raise error
    end
  end

  @impl true
  def handle_call(:get, _from, state = {_user_id, track, _creds}) do
    {:reply, track, state}
  end

  @impl true
  def handle_info(:work, state) do
    try do
      new_state = get_playing_track(state)
      schedule_get()
      {:noreply, new_state}
    rescue
      error -> Logger.error Exception.format(:error, error, __STACKTRACE__)
               raise error
    end
  end

  defp schedule_get do
    # In 2 hours
    Process.send_after(self(), :work, 1 * 1000)
  end

  defp get_playing_track(state) do
    {user_id, _, creds = %Credentials{}} = state

    success = Api.get_playing_track(user_id, creds)

    {user_id, success.result, success.credentials}
  end

end
