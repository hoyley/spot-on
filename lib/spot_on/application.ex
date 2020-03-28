defmodule SpotOn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @enable_spotify_workers Application.get_env(:spot_on, :enable_spotify_workers)

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      SpotOn.Repo,
      # Start the endpoint when the application starts
      SpotOnWeb.Endpoint,
      %{
        id: Phoenix.PubSub.PG2,
        start: {Phoenix.PubSub.PG2, :start_link, [:spot_on, []]}
      }
    ] ++ get_spotify_workers()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpotOn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SpotOnWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def get_spotify_workers() do
    case @enable_spotify_workers do
      true -> [ SpotOn.Gen.FollowerSupervisor,
                SpotOn.Gen.Initializer ]
      false -> []
    end
  end
end
