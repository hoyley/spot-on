defmodule SpotOnWeb.UserTrackLeader do
  use Phoenix.LiveComponent
  alias SpotOn.Model.User

  def render(assigns) do
    ~L"""
      <div>
        <%= unless @leader == nil do %>
          <%= 'Following #{@leader.display_name}' %>
          <%= if @logged_in_user_can_unfollow do %>
            <button id="<%= @id %>" phx-click="unfollow" phx-target="<%= '##{@id}' %>">Unfollow</button>
          <% end %>
        <% end %>
      </div>
    """
  end

  def update(
        %{
          id: id,
          leader: leader,
          logged_in_user_can_unfollow: logged_in_user_can_unfollow
        },
        socket
      ) do
    new_socket =
      socket
      |> assign(:leader, leader)
      |> assign(:logged_in_user_can_unfollow, logged_in_user_can_unfollow)
      |> assign(:id, id)

    {:ok, new_socket}
  end

  def handle_event("unfollow", _params, socket = %{assigns: %{leader: nil}}),
    do: {:noreply, socket}

  def handle_event(
        "unfollow",
        _params,
        socket = %{assigns: %{leader: %User{name: leader_name}}}
      ) do
    send(self(), {:unfollow, leader_name})
    {:noreply, socket}
  end
end
