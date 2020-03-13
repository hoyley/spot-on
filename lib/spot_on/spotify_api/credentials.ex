# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule SpotOn.SpotifyApi.Credentials do
  @moduledoc """
  Provides a struct to hold token credentials from Spotify.

  These consist of an access token, used to authenticate requests to the Spotify
  web API, as well as a refresh token, used to request a new access token when
  it expires.

  You can use this struct in the place of a `Plug.Conn` struct anywhere in this
  library's functions with one caveat: If you use a `Plug.Conn`, these tokens
  will be persisted for you in browser cookies. However, if you choose to use
  `SpotOn.SpotifyApi.Credentials`, it will be your responsibility to persist this data
  between uses of the library's functions. This is convenient if your use case
  involves using this library in a situation where you don't have access to a
  `Plug.Conn` or a browser/cookie system.

  ## Example:

      defmodule SpotifyExample do
        @moduledoc "This example uses an `Agent` to persist the tokens"

        @doc "The `Agent` is started with an empty `Credentials` struct"
        def start_link do
          Agent.start_link(fn -> %SpotOn.SpotifyApi.Credentials{} end, name: CredStore)
        end

        defp get_creds, do: Agent.get(CredStore, &(&1))

        defp put_creds(creds), do: Agent.update(CredStore, fn(_) -> creds end)

        @doc "Used to link the user to Spotify to kick off the auth process"
        def auth_url, do: SpotOn.SpotifyApi.Authorization.url

        @doc "`params` are passed to your callback endpoint from Spotify"
        def authenticate(params) do
          creds = get_creds()
          {:ok, new_creds} = SpotOn.SpotifyApi.Authentication.authenticate(creds, params)
          put_creds(new_creds) # make sure to persist the credentials for later!
        end

        @doc "Use the credentials to access the Spotify API through the library"
        def track(id) do
          credentials = get_creds()
          {:ok, track} = Track.get_track(credentials, id)
          track
        end
      end
  """
  alias SpotOn.Model.UserTokens
  alias SpotOn.SpotifyApi.Credentials

  defstruct [:access_token, :refresh_token]

  @doc """
  Returns a SpotOn.SpotifyApi.Credentials struct from either a Plug.Conn or a SpotOn.SpotifyApi.Credentials struct
  """
  def new(conn_or_credentials)
  def new(creds = %Credentials{}), do: creds

  def new(conn = %Plug.Conn{}) do
    conn = Plug.Conn.fetch_cookies(conn)
    access_token = conn.cookies["spotify_access_token"]
    refresh_token = conn.cookies["spotify_refresh_token"]
    Credentials.new(access_token, refresh_token)
  end

  def new(%UserTokens{} = tokens) do
    Credentials.new(tokens.access_token, tokens.refresh_token)
  end

  @doc """
  Returns a SpotOn.SpotifyApi.Credentials struct given tokens
  """
  def new(access_token, refresh_token) do
    %Credentials{access_token: access_token, refresh_token: refresh_token}
  end

  @doc """
  Returns a SpotOn.SpotifyApi.Credentials struct from a parsed response body
  """
  def get_tokens_from_response(map)

  def get_tokens_from_response(response) do
    Credentials.new(response["access_token"], response["refresh_token"])
  end
end
