defmodule SpotOnWeb.UserTrackFollower do
  use Phoenix.LiveComponent
  alias SpotOn.Model.User
  alias SpotOnWeb.Router.Helpers, as: Routes

  def render(assigns) do
    ~L"""
    <%= if @logged_in_user_can_follow do %>
      <a href="<%= Routes.page_path(@socket, :follow, leader: @leader_name) %>">Follow</a>
    <% end %>
    """
  end

  def update(%{potential_leader: potential_leader = %User{}, current_leader: nil,
    logged_in_user_name: logged_in_user_name}, socket) do
    {:ok, socket
        |> assign(:logged_in_user_can_follow, logged_in_user_can_follow(logged_in_user_name, potential_leader))
        |> assign(:leader_name, potential_leader.name)
    }
  end

  def update(%{potential_leader: potential_leader = %User{}, current_leader: %User{}}, socket) do
    {:ok, socket
          |> assign(:logged_in_user_can_follow, false)
          |> assign(:leader_name, potential_leader.name)
    }
  end

  def logged_in_user_can_follow(logged_in_user_name, potential_leader) do
    logged_in_user_name !== potential_leader.name
  end

end
