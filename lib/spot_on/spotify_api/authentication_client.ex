# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule AuthenticationClient do
  @moduledoc false

  alias HTTPoison.Response
  alias HTTPoison.Error
  alias SpotOn.SpotifyApi.Client

  @auth_url "https://accounts.spotify.com/api/token"

  def post(params) do
    with {:ok, %Response{status_code: _code, body: body}} <-
           Client.authenticate(@auth_url, params),
         {:ok, response} <- Poison.decode(body) do
      case response do
        %{"error_description" => error} ->
          raise(AuthenticationError, "The Spotify API responded with: #{error}")

        success_response ->
          {:ok, SpotOn.SpotifyApi.Credentials.get_tokens_from_response(success_response)}
      end
    else
      {:error, %Error{reason: reason}} ->
        {:error, reason}

      _generic_error ->
        raise(AuthenticationError, "Error parsing response from Spotify")
    end
  end
end
