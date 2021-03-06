# SpotOn

SpotOn turns any Spotify user into a live DJ. Followers, who are also Spotify users, can listen to the DJ's currently playing track on their active Spotify player.

The application is written in Elixir and leverages the Spotify API. This application is currently hosted on Gigilixir, but access is limited (request for demo).

Images/Screenshots to come.

## Dependencies
- Elixir
- NPM
- Docker

### Secrets Configuration
In order to connect to Spotify you will need to add a file `/config/secret.exs` which contains Spotify secrets. 
Here is an example:

```elixir
use Mix.Config

config :spot_on, client_id: "YOUR SPOTIFY CLIENT ID",
                 secret_key: "YOUR SPOTIFY SECRET KEY"
```   

## Running the Application

```bash
docker-compose up -d db             # Start the database docker image in detached mode
mix deps.get                        # Pull dependencies for Elixir
mix ecto.setup                      # Configure the spot-on database
cd assets && npm install & cd ..    # Install npm packages
mix test                            # Run tests
mix phx.server                      # Run the webserver outside of docker 

```

Once you've installed mix dependencies and run ecto.setup, you can now build and run in docker. To build the web server 
in docker, run `docker-compose build`. To run the web server in docker, run `docker-compose up web`.

## Building for Production

```bash
mix deps.get --only prod
MIX_ENV=prod mix compile
cd assets && npm install & cd ..
npm run deploy --prefix ./assets
mix phx.digest
MIX_ENV=prod docker-compose build
```
