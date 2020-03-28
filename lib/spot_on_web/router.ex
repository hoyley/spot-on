defmodule SpotOnWeb.Router do
  use SpotOnWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash,
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {SpotOnWeb.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpotOnWeb do
    pipe_through :browser

    live "/users", UserTrackList

    get "/", PageController, :index
    get "/logout", PageController, :logout
    get "/unfollow", PageController, :unfollow
    get "/follow", PageController, :follow
    get "/authenticate", AuthController, :authenticate
    get "/authorize", AuthController, :authorize
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpotOnWeb do
  #   pipe_through :api
  # end
end
