# SpotOn

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

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
docker-compose up -d db             # Start the database docdker image in detached mode
mix deps.get                        # Pull dependencies for Elixir
mix ecto.setup                      # Configure the spot-on database
cd assets && npm install & cd ..    # Install npm packages
mix test                            # Run tests
mix phx.server                      # Run the webserver outside of docker 

```

Once you've installed mix dependencies and run ecto.setup, you can now build and run in docker. To build the web server 
in docker, run `docker-compose build`. To run the web server in docker, run `docker-compose up web`.
