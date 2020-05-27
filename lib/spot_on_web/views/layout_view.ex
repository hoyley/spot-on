defmodule SpotOnWeb.LayoutView do
  use SpotOnWeb, :view
  alias Plug.Conn
  import Plug.Conn

  def logged_in_user_name(conn = %Conn{}) do
    conn |> get_session(:logged_in_user_display_name)
  end
end
