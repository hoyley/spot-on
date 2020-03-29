defmodule SpotOnWeb.UserLastActivity do
  use Phoenix.LiveComponent
  alias SpotOn.Model.User

  def render(assigns) do
    ~L"""
      <div class="card-subtitle text-gray h6 text-normal text-ellipsis">
        <%= @last_activity %>
      </div>
    """
  end

  def update(%{user: user = %User{}}, socket) do
    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:last_activity, last_activity(user))}
  end

  def last_activity(user = %User{}) do
    login_activity = how_long_ago(user.last_login)
    spotify_activity = how_long_ago(user.last_spotify_activity)

    "Logged in #{login_activity}. Spotify active #{spotify_activity}."
  end

  def how_long_ago(date) do
    minute_difference = trunc(DateTime.diff(DateTime.utc_now(), date, :second) / 60)

    hour_difference = trunc(minute_difference / 60)
    day_difference = trunc(hour_difference / 24)

    cond do
      minute_difference <= 5 -> "currently"
      minute_difference < 60 -> "#{minute_difference} minutes ago"
      hour_difference == 1 -> "#{hour_difference} hour ago"
      hour_difference < 24 -> "#{hour_difference} hours ago"
      day_difference == 1 -> "#{day_difference} day ago"
      true -> "#{day_difference} days ago"
    end
  end
end
