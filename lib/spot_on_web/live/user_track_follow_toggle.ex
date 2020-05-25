defmodule SpotOnWeb.UserTrackFollowToggle do
  use Phoenix.LiveComponent
  use Phoenix.HTML
  alias SpotOn.Model.User
  require Logger

  def render(assigns) do
    ~L"""
    <div>
      <%= if @visible do %>
        <div class="form-group">
          <fieldset <%= @disabled_state %>>
            <label class="form-switch">
              <%= checkbox(:user_card, :follow, phx_click: "follow", phx_target: @myself, value: @toggle_state) %>
              <i class="form-icon"></i>Follow
            </label>
          </fieldset>
        </div>
      <% end %>
    </div>
    """
  end

  def update(
        %{
          logged_in_user_name: logged_in_user_name,
          logged_in_user_leader: logged_in_user_leader,
          card_user: card_user = %User{}
        },
        socket
      ) do
    visible = logged_in_user_name != card_user.name

    disabled_state =
      case (logged_in_user_leader != nil && logged_in_user_leader.name !== card_user.name) do
        true -> "disabled"
        false -> ""
      end

    toggle_state = logged_in_user_leader != nil && logged_in_user_leader.name === card_user.name

    {:ok,
     socket
     |> assign(:card_user_name, card_user.name)
     |> assign(:card_user, card_user)
     |> assign(:visible, visible)
     |> assign(:disabled_state, disabled_state)
     |> assign(:toggle_state, toggle_state)}
  end

  def handle_event(
        "follow",
        _state,
        socket = %{assigns: %{card_user_name: card_user_name, toggle_state: false}}
      ) do
    send(self(), {:follow, card_user_name})

    {:noreply, socket}
  end

  def handle_event(
        "follow",
        _state,
        socket = %{assigns: %{card_user_name: card_user_name, toggle_state: true}}
      ) do
    send(self(), {:unfollow, card_user_name})

    {:noreply, socket}
  end
end
