use Mix.Config

config :spot_on, user_id: "fake",
                    scopes: ["app-remote-control", "user-read-currently-playing"],
                    callback_url: "http://localhost:4000/authenticate"
