# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule SpotOn.SpotifyApi.AuthenticationClient do
  @moduledoc false
  use Responder
  alias SpotOn.SpotifyApi.Client
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Credentials

  @auth_url "https://accounts.spotify.com/api/token"

  def post(params, creds = %Credentials{}) do
    Client.authenticate(@auth_url, params)
    |> handle_response(creds)
    |> handle_post_response()
  end

  defp handle_post_response(response = %ApiSuccess{result: %{"access_token" => _}}),
    do: Credentials.get_tokens_from_response(response.result) |> ApiSuccess.new()

  defp handle_post_response(%ApiSuccess{credentials: creds}),
    do:
      ApiFailure.new(
        creds,
        "Error parsing response from Spotify during authentication. No code was provided"
      )

  defp handle_post_response(
         response = %ApiFailure{result: %{"error_description" => error_description}}
       ),
       do: ApiFailure.new(response.credentials, error_description, :auth_error)

  defp handle_post_response(response = %ApiFailure{}),
    do: response

  def build_response(body), do: body
end
