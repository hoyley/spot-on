defmodule SpotOn.SpotifyApi.ApiHelpers do

  defmacro __using__(_) do
    quote do
      alias SpotOn.SpotifyApi.Authentication
      alias SpotOn.SpotifyApi.Profile
      alias SpotOn.SpotifyApi.Credentials
      alias SpotOn.SpotifyApi.ApiFailure
      alias SpotOn.SpotifyApi.ApiSuccess
      alias SpotOn.Model
      require Logger

      def call(conn = %Plug.Conn{}, api_function), do: call(conn |> Credentials.new, api_function, true)
      def call(credentials = %Credentials{}, api_function), do: call(credentials, api_function, true)
      def call(credentials = %Credentials{}, api_function, allow_refresh \\ false) do
        api_function.(credentials)
        |> response(credentials)
        |> handle_call_response(api_function, allow_refresh)
      end

      defp handle_call_response(result = %ApiSuccess{}, _, _), do: result
      defp handle_call_response(failure = %ApiFailure{status: 401, credentials: credentials}, api_function, true) do
        Logger.info "Attempted to call API Endpoint received #{failure.status} - [#{failure.message}]. Refresh will follow."
        refresh(credentials)
        |> handle_refresh_response(api_function)
      end
      defp handle_call_response(failure = %ApiFailure{}, _, _), do: failure

      defp handle_refresh_response(fail = %ApiFailure{}, _), do: fail
      defp handle_refresh_response(success = %ApiSuccess{}, api_function), do: call(success.credentials, api_function, false)

      def refresh(credentials = %Credentials{}) do
        Logger.debug "Attempting to refresh connection"

        try do
          Authentication.refresh(credentials)
          |> parse_credentials(credentials)
          |> update_tokens_internal
        rescue
          e in AuthenticationError -> ApiFailure.new(e.message, nil, credentials)
        end
      end

      defp parse_credentials({:ok, partial_creds = %Credentials{}}, creds = %Credentials{}) do
        Credentials.new(partial_creds.access_token, creds.refresh_token)
      end

      defp update_tokens_internal(creds = %Credentials{}) do
        creds
        |> Profile.me
        |> response(creds)
        |> update_tokens_internal
      end

      defp update_tokens_internal(success = %ApiSuccess{result: %Profile{id: spotify_id}, credentials: credentials}) do
        Model.create_or_update_user_tokens(spotify_id, credentials)
        success
      end

      defp update_tokens_internal(failure = %ApiFailure{}), do: failure

      def response({:ok, %{"error" => %{"message" => error_message, "status" => error_status}}},
            credentials = %Credentials{}) do
        ApiFailure.new(error_message, error_status, credentials)
      end

      def response({:error, message}, credentials = %Credentials{}) do
        ApiFailure.new(message, nil, credentials)
      end

      def response({:ok, response}, credentials = %Credentials{}) do
        ApiSuccess.new(response, credentials)
      end

      def response(response, credentials = %Credentials{}) do
        ApiSuccess.new(response, credentials)
      end

    end
  end
end
