use Mix.Config

# Configure your database
config :spot_on, SpotOn.Repo,
  username: "postgres",
  password: "postgres",
  database: "spot-on",
  hostname: "localhost",
  port: 5435,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :spot_on, SpotOnWeb.Endpoint,
  http: [port: 4002],
  server: false

config :spot_on, api_client: ClientBehaviorMock,
                 enable_spotify_workers: false

# Print only warnings and errors during test
config :logger, level: :warn
