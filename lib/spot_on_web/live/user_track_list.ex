defmodule SpotOnWeb.UserTrackList do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <div class="container user-cards grid-xs">
        <div class="user-card-columns columns">
          <%= for user <- @users do %>
            <div class="user-card-column column">
              <div class="card user-card text-ellipsis">
              <%= live_render @socket, SpotOnWeb.UserTrack, id: 'user_track-#{user.name}', user: user,
                  session: %{
                    "logged_in_user_name" => @logged_in_user.name,
                    "user_name" => user.name,
                    "spotify_access_token" => @spotify_credentials.access_token,
                    "spotify_refresh_token" => @spotify_credentials.refresh_token,
                    "display_mode" => @display_mode} %>
                    </div>
            </div>
          <% end %>
        </div>
      </div>
    """
  end
end
