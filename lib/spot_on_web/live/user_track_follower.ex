defmodule SpotOnWeb.UserTrackFollower do
  use Phoenix.LiveComponent
  alias SpotOn.Model.User
  require Logger

  def render(assigns) do
    ~L"""
    <div>
      <%= if @logged_in_user_can_follow do %>
        <button id="<%= @id %>" phx-click="follow" phx-target="<%= '##{@id}' %>">Follow</button>
      <% end %>
    </div>
    """
  end

  def update(
        %{
          id: id,
          logged_in_user_can_follow: logged_in_user_can_follow,
          user: user = %User{}
        },
        socket
      ) do
    {:ok,
     socket
     |> assign(:logged_in_user_can_follow, logged_in_user_can_follow)
     |> assign(:id, id)
     |> assign(:user, user)}
  end

  def handle_event(
        "follow",
        _params,
        socket = %{assigns: %{user: %User{name: user_name}}}
      ) do
    send(self(), {:follow, user_name})

    {:noreply, socket}
  end
end
