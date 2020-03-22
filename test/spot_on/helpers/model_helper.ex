defmodule SpotOn.Helpers.ModelHelper do
  import SpotOn.Helpers.Defaults
  alias SpotOn.Model
  alias SpotOn.SpotifyApi.Credentials

  def create_user_and_tokens(), do: create_user_and_tokens(default_user_name())
  def create_user_and_tokens(user_name), do: create_user_and_tokens(user_name, default_user_display_name(),
    default_access_token(), default_refresh_token())

  def create_user_and_tokens(user_name, display_name, access_token, refresh_token) do
    user = Model.create_user(%{name: user_name, display_name: display_name})
    tokens = Model.create_user_tokens(%{user_id: user.id, access_token: access_token, refresh_token: refresh_token})
    creds = tokens |> Credentials.new

    %{user: user, tokens: tokens, creds: creds}
  end
end
