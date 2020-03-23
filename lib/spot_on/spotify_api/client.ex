# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule SpotOn.SpotifyApi.ClientBehavior do

  @moduledoc false
  @callback get(Any.t(), String.t()) :: tuple()
  @callback put(Any.t(), String.t()) :: tuple()
  @callback put(Any.t(), String.t(), Any.t()) :: tuple()
  @callback post(Any.t(), String.t(), Any.t()) :: tuple()
  @callback delete(Any.t(), String.t()) :: tuple()
  @callback authenticate(String.t(), String.t()) :: tuple()
end

defmodule SpotOn.SpotifyApi.Client do
  require Logger
  @moduledoc false
  def api_client, do: Application.get_env(:spot_on, :api_client)
  @behaviour SpotOn.SpotifyApi.ClientBehavior

  def get(conn_or_creds, url) do
    api_client().get(conn_or_creds, url)
      |> log(url)
  end

  def put(conn_or_creds, url, body \\ "") do
    api_client().put(conn_or_creds, url, body)
    |> log(url)
  end

  def post(conn_or_creds, url, body \\ "") do
    api_client().post(conn_or_creds, url, body)
    |> log(url)
  end

  def delete(conn_or_creds, url) do
    api_client().delete(conn_or_creds, url)
    |> log(url)
  end

  def authenticate(url, params) do
    api_client().authenticate(url, params)
    |> log(url)
  end

  defp log(result, url) do
    Logger.debug('Api URL [#{url}] returned: #{inspect(result)}')
    result
  end
end

defmodule SpotOn.SpotifyApi.ClientImpl do
  @moduledoc false
  @behaviour SpotOn.SpotifyApi.ClientBehavior

  def get(conn_or_creds, url) do
    HTTPoison.get(url, get_headers(conn_or_creds))
  end

  def put(conn_or_creds, url, body \\ "") do
    HTTPoison.put(url, body, put_headers(conn_or_creds))
  end

  def post(conn_or_creds, url, body \\ "") do
    HTTPoison.post(url, body, post_headers(conn_or_creds))
  end

  def delete(conn_or_creds, url) do
    HTTPoison.delete(url, delete_headers(conn_or_creds))
  end

  def authenticate(url, params) do
    HTTPoison.post(url, params, auth_headers())
  end

  def get_headers(conn_or_creds) do
    [{"Authorization", "Bearer #{access_token(conn_or_creds)}"}]
  end

  def put_headers(conn_or_creds) do
    [
      {"Authorization", "Bearer #{access_token(conn_or_creds)}"},
      {"Content-Type", "application/json"}
    ]
  end

  def auth_headers do
    [
      {"Authorization", "Basic #{SpotifyConfig.encoded_credentials()}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
  end

  defp access_token(conn_or_creds) do
    SpotOn.SpotifyApi.Credentials.new(conn_or_creds).access_token
  end

  def post_headers(conn_or_creds), do: put_headers(conn_or_creds)
  def delete_headers(conn_or_creds), do: get_headers(conn_or_creds)
end
