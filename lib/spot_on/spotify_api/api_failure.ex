defmodule SpotOn.SpotifyApi.ApiFailure do
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Credentials

  @type status ::
          :unknown
          | :http_error
          | :timeout
          | :connection_closed
          | :unreachable
          | :enet_down
          | :rate_limit
          | :auth_error
          | :refresh_revoked

  defstruct message: nil,
            status: nil,
            http_status: nil,
            credentials: nil,
            result: nil

  def new(credentials = %Credentials{}, status = :timeout),
    do: new(credentials, "The connection timed out.", status)

  def new(credentials = %Credentials{}, status = :connection_closed),
    do: new(credentials, "The connection was closed.", status)

  def new(credentials = %Credentials{}, status = :unreachable),
    do: new(credentials, "The API is unreachable.", status)

  def new(credentials = %Credentials{}, status = :rate_limit),
    do: new(credentials, "The rate limit has been reached.", status)

  def new(credentials = %Credentials{}, status = :enet_down),
    do: new(credentials, "No internet connection found.", status)

  def new(credentials = %Credentials{}, status = :refresh_revoked),
    do: new(credentials, "The user's Spotify refresh token was revoked.", status)

  @spec new(%Credentials{}, String.t()) :: %ApiFailure{}
  def new(credentials = %Credentials{}, message), do: new(credentials, message, :unknown)

  def new(credentials = %Credentials{}, status = :rate_limit, retry_after),
    do:
      new(credentials, "Exceeded Spotify API Rate Limit.", status, 429, %{retry_after: retry_after})

  def new(credentials = %Credentials{}, :http_error, 429), do: new(credentials, :rate_limit)

  def new(credentials = %Credentials{}, :http_error, http_status),
    do: new(credentials, "An HTTP error occurred [#{http_status}]", :http_error, http_status)

  @spec new(%Credentials{}, String.t(), status) :: %ApiFailure{}
  def new(credentials = %Credentials{}, message, status),
    do: %ApiFailure{message: message, status: status, credentials: credentials}

  @spec new(%Credentials{}, String.t(), status, pos_integer()) :: %ApiFailure{}
  def new(credentials = %Credentials{}, message, status, http_status) do
    %ApiFailure{
      message: message,
      status: status,
      credentials: credentials,
      http_status: http_status
    }
  end

  @spec new(%Credentials{}, String.t(), status, pos_integer(), any()) :: %ApiFailure{}
  def new(credentials = %Credentials{}, message, status, http_status, result) do
    %ApiFailure{
      message: message,
      status: status,
      credentials: credentials,
      http_status: http_status,
      result: result
    }
  end
end
