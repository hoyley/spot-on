# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :spot_on,
  ecto_repos: [SpotOn.Repo]

# Configures the endpoint
config :spot_on, SpotOnWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "288cC4WgDoJsDbLh199v6eYOILYcH+MCVU/9u8kuTtfrPXui05RSuIewTNjd8qMA",
  render_errors: [view: SpotOnWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SpotOn.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "oCaaA7x2"]

config :spot_on, enable_spotify_workers: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, template_engines: [leex: Phoenix.LiveView.Engine]

config :spot_on, api_client: SpotOn.SpotifyApi.ClientImpl

config :spot_on, playing_track_poll_ms: 1000,
                 follower_poll_ms: 1000,
                 follower_threshold_ms: 2000,
                 spotify_set_playing_song_delay_ms: 100

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
import_config "spotify.exs"
import_config "secret.exs"
