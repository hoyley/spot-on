defmodule SpotOn.SpotifyApi.Api do
  alias SpotOn.SpotifyApi.Authentication
  alias SpotOn.SpotifyApi.Profile
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.Model

  def call(conn = %Plug.Conn{}, api_function), do: call(conn |> Credentials.new, api_function, true)
  def call(credentials = %Credentials{}, api_function), do: call(credentials, api_function, true)
  def call(credentials = %Credentials{}, api_function, allow_refresh \\ false) do
    try do
      api_function.(credentials) |> IO.inspect
    rescue
      e in FunctionClauseError -> handle_api_function_error(e)
    end
      |> ApiFailure.wrap
      |> handle_call_response(credentials, api_function, allow_refresh)
  end

  def handle_api_function_error(error), do: raise error

  defp handle_call_response(failure = %ApiFailure{status: 401}, credentials = %Credentials{}, api_function, true) do
    IO.puts "Attempted to call API Endpoint received #{failure.status} - [#{failure.message}]. Refresh will follow."
    refresh(credentials)
      |> handle_refresh_response(api_function)
  end
  defp handle_call_response(result, _, _, _), do: result

  defp handle_refresh_response(failure = %ApiFailure{}, _), do: failure
  defp handle_refresh_response(credentials = %Credentials{}, api_function), do: call(credentials, api_function, false)

  def refresh(credentials = %Credentials{}) do
    IO.puts "Attempting to refresh connection"

    try do
      Authentication.refresh(credentials)
        |> parse_credentials(credentials)
        |> update_tokens()
    rescue
      e in AuthenticationError -> ApiFailure.new(e.message)
    end
  end

  defp parse_credentials({:ok, partial_creds = %Credentials{}}, creds = %Credentials{}) do
    Credentials.new(partial_creds.access_token, creds.refresh_token)
  end

  def update_tokens(conn_or_creds) do
    conn_or_creds
      |> call(&Profile.me/1)
      |> update_tokens(conn_or_creds)
  end

  defp update_tokens(failure = %ApiFailure{}, _), do: failure
  defp update_tokens({:ok, %{id: spotify_id}}, conn_or_creds) do
    creds = conn_or_creds |> Credentials.new()
    Model.create_or_update_user_tokens(spotify_id, creds)
    conn_or_creds
  end

end
