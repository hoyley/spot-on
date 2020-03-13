# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule SpotifyConfig do
  @moduledoc false

  def client_id, do: Application.get_env(:spot_on, :client_id)
  def secret_key, do: Application.get_env(:spot_on, :secret_key)
  def current_user, do: Application.get_env(:spot_on, :user_id)

  def callback_url do
    Application.get_env(:spot_on, :callback_url) |> URI.encode_www_form()
  end

  def encoded_credentials, do: :base64.encode("#{client_id()}:#{secret_key()}")
end
