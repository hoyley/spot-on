defmodule SpotOnWeb.UserTrackFollower do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <div>
        <%= unless @card_user_leader == nil do %>
          <%= 'Following #{@card_user_leader.display_name}' %>
        <% end %>
      </div>
    """
  end

  def update(
        %{
          card_user_leader: card_user_leader,
        },
        socket
      ) do
    new_socket =
      socket
      |> assign(:card_user_leader, card_user_leader)

    {:ok, new_socket}
  end

end
