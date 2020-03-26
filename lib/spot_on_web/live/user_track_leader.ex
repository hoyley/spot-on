defmodule SpotOnWeb.UserTrackLeader do
  use Phoenix.LiveComponent
  alias SpotOn.Model.User
  alias SpotOnWeb.Router.Helpers, as: Routes

  def render(assigns) do
    ~L"""
      <%= unless @leader == nil do %>
        <div>
          <%= 'Following #{@leader.display_name}' %>
          <%= if @user_can_unfollow do %>
            <a href="<%= Routes.page_path(@socket, :unfollow, follower: @follower.name, leader: @leader.name) %>">Unfollow</a>
          <% end %>
        </div>
      <% end %>
    """
  end

  def update(%{user: user = %User{}, leader: leader, logged_in_user_name: logged_in_user_name}, socket) do
    new_socket = socket
    |> assign(:leader, leader)
    |> assign(:follower, user)
    |> assign(:user_can_unfollow, logged_in_user_name === user.name)

    {:ok, new_socket}
  end
end
