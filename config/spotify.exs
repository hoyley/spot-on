use Mix.Config

config :spot_on,
  user_id: "fake",
  scopes: [
    "app-remote-control",
    "user-read-currently-playing",
    "user-modify-playback-state"
  ],
  callback_url: "authenticate"
