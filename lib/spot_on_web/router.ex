defmodule SpotOnWeb.Router do
  use SpotOnWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session

    plug :fetch_flash,
         plug(Phoenix.LiveView.Flash)

    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {SpotOnWeb.LayoutView, :layout}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpotOnWeb do
    pipe_through :browser

    live "/users", UsersView
    live "/room/:user_name", UserRoom

    get "/", PageController, :index
    get "/home", PageController, :home
    get "/logout", PageController, :logout
    get "/error", PageController, :error
    get "/authenticate", AuthController, :authenticate
    get "/authorize", AuthController, :authorize
  end

  if Mix.env() == :dev do
    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SpotOnWeb.Telemetry
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpotOnWeb do
  #   pipe_through :api
  # end
end
