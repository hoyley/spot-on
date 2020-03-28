defmodule SpotOnWeb.UserLastActivity do
  use Phoenix.LiveComponent
  alias SpotOn.Model.User

  def render(assigns) do
    ~L"""
      <div class="card-subtitle text-gray"><%= @last_activity %></div>
    """
  end

  def update(%{user: user = %User{}}, socket) do
    {:ok, socket
          |> assign(:user, user)
          |> assign(:last_activity, last_activity(user))}
  end

  def last_activity(user = %User{}) do
    minute_difference = trunc(DateTime.diff(DateTime.utc_now(), user.last_login, :second) / 60)
    hour_difference = trunc(minute_difference / 60)
    day_difference = trunc(hour_difference / 24)

    cond do
      minute_difference <= 5 -> "Currently active"
      minute_difference < 60 -> "#{minute_difference} minutes ago"
      hour_difference == 1 -> "#{hour_difference} hour ago"
      hour_difference < 24 -> "#{hour_difference} hours ago"
      day_difference == 1 -> "#{day_difference} day ago"
      true -> "#{day_difference} days ago"
    end
  end
end
