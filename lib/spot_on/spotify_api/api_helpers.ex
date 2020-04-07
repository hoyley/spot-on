defmodule SpotOn.SpotifyApi.ApiHelpers do
  defmacro __using__(_) do
    quote do
      alias SpotOn.SpotifyApi.Authentication
      alias SpotOn.SpotifyApi.Profile
      alias SpotOn.SpotifyApi.Credentials
      alias SpotOn.SpotifyApi.ApiFailure
      alias SpotOn.SpotifyApi.ApiSuccess
      alias SpotOn.Model
      alias SpotOn.Model.User
      alias SpotOn.Actions
      require Logger

      def call(conn = %Plug.Conn{}, api_function),
        do: call(conn |> Credentials.new(), api_function, true)

      def call(credentials = %Credentials{}, api_function),
        do: call(credentials, api_function, true)

      def call(
            credentials = %Credentials{},
            api_function,
            allow_refresh \\ false
          ) do
        api_function.(credentials)
        |> handle_call_response(api_function, allow_refresh)
      end

      defp handle_call_response(result = %ApiSuccess{}, _, _), do: result

      defp handle_call_response(
             failure = %ApiFailure{credentials: credentials, http_status: 429},
             api_function,
             true
           ) do
        wait = (failure.result && Map.get(failure.result, "retry_after")) || 1
        :timer.sleep(wait * 1000)

        refresh(credentials)
        |> handle_refresh_response(api_function)
      end

      defp handle_call_response(
             failure = %ApiFailure{credentials: credentials, http_status: 401},
             api_function,
             true
           ) do
        Logger.info("Attempted to call API Endpoint and received 401. Refresh will follow.")

        refresh(credentials)
        |> handle_refresh_response(api_function)
      end

      defp handle_call_response(failure = %ApiFailure{}, _api_function, _), do: failure

      defp handle_refresh_response(fail = %ApiFailure{}, _), do: fail

      defp handle_refresh_response(success = %ApiSuccess{}, api_function),
        do: call(success.credentials, api_function, false)

      def refresh(credentials = %Credentials{}) do
        Logger.debug("Attempting to refresh connection")

        case Authentication.refresh(credentials) do
          failure = %ApiFailure{} ->
            failure

          success = %ApiSuccess{} ->
            success
            |> enrich_credentials(credentials)
            |> Map.get(:credentials)
            |> Actions.update_my_user_tokens()
        end
      end

      defp enrich_credentials(
             success = %ApiSuccess{},
             creds = %Credentials{}
           ) do
        Credentials.new(success.credentials.access_token, creds.refresh_token)
        |> ApiSuccess.new(success.result)
      end
    end
  end
end
