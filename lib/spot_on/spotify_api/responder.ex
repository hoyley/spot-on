# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule Responder do
  @moduledoc """
  Receives http responses from the client and handles them accordingly.

  Spotify API modules (Playlist, Album, etc) `use Responder`. When a request
  is made they give the endpoint URL to the Client, which makes the request,
  and pass the response to `handle_response`. Each API module must build
  appropriate responses, so they add Responder as a behaviour, and implement
  the `build_response/1` function.
  """

  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Credentials

  @callback build_response(map) :: any

  defmacro __using__(_) do
    quote do
      require Logger
      @default_retry_after 2


      # special handling for 'too many requests' status
      # in order to know when to retry
      def handle_response(
            {message, %HTTPoison.Response{status_code: 429, headers: headers}},
            conn
          ) do
        retry_after = headers |> get_retry_after

        ApiFailure.new(conn, :rate_limit, retry_after)
      end

      def handle_response(
            {message, %HTTPoison.Response{status_code: 400, body: body}},
            conn
          ) do
        case body |> Poison.decode!() do
          %{"error" => "invalid_grant"} ->
            ApiFailure.new(
              conn |> Credentials.new(),
              :refresh_revoked
            )

          decoded_body ->
            ApiFailure.new(
              conn |> Credentials.new(),
              :http_error,
              400,
              decoded_body
            )
        end
      end

      def handle_response({message, %HTTPoison.Response{status_code: code, body: body}}, conn)
          when code in 400..499 do
        ApiFailure.new(
          conn |> Credentials.new(),
          :http_error,
          code
        )
      end

      def handle_response({:ok, %HTTPoison.Response{status_code: code, body: ""}}, conn)
          when code in 200..299,
          do: ApiSuccess.new(conn |> Credentials.new())

      def handle_response({:ok, poison = %HTTPoison.Response{body: body}}, conn) do
        response = body |> Poison.decode!() |> build_response
        handle_ok_response(conn |> Credentials.new(), response)
      end

      def handle_response({:error, %HTTPoison.Error{id: nil, reason: :enetdown}}, conn),
        do: ApiFailure.new(conn |> Credentials.new(), :enet_down)

      def handle_response({:error, %HTTPoison.Error{id: nil, reason: :nxdomain}}, conn),
        do: ApiFailure.new(conn |> Credentials.new(), :unreachable)

      def handle_response({:error, %HTTPoison.Error{id: nil, reason: :closed}}, conn),
        do: ApiFailure.new(conn |> Credentials.new(), :connection_closed)

      def handle_response({:error, %HTTPoison.Error{id: nil, reason: :connect_timeout}}, conn),
        do: ApiFailure.new(conn |> Credentials.new(), :timeout)

      def handle_response({:error, %HTTPoison.Error{id: nil, reason: :timeout}}, conn),
        do: ApiFailure.new(conn |> Credentials.new(), :timeout)

      defp handle_ok_response(
             credentials = %Credentials{},
             %{
               "error" => %{
                 "message" => error_message,
                 "status" => error_status
               }
             }
           ),
           do: ApiFailure.new(credentials, error_message, :http_error, error_status)

      defp handle_ok_response(credentials = %Credentials{}, {:error, message}),
        do: ApiFailure.new(credentials, message)

      defp handle_ok_response(credentials = %Credentials{}, {:ok, response}),
        do: ApiSuccess.new(credentials, response)

      defp handle_ok_response(credentials = %Credentials{}, response),
        do: ApiSuccess.new(credentials, response)

      defp get_retry_after(headers) do
        retry_after_header = headers |> Enum.find(&(Kernel.elem(&1, 0) == "Retry-After"))
        Logger.info("Spotify returned Retry-After header: #{inspect(retry_after_header)}")

        retry_after_header |> parse_retry_header
      end

      defp parse_retry_header(retry_after_header) do
        if retry_after_header && Kernel.tuple_size(retry_after_header) > 1 do
          retry_after_header
          |> Kernel.elem(1)
          |> Integer.parse()
        else
          @default_retry_after
        end
      end
    end
  end
end
