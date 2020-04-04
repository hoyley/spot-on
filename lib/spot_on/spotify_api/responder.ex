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
      def handle_response({message, %HTTPoison.Response{status_code: code, body: body}}, conn)
          when code in 400..499 do
        ApiFailure.new(
          conn |> Credentials.new(),
          message,
          :http_error,
          code,
          body && Poison.decode!(body)
        )
      end

      def handle_response({:ok, %HTTPoison.Response{status_code: code, body: ""}}, conn)
          when code in 200..299,
          do: ApiSuccess.new(conn |> Credentials.new())

      def handle_response({:ok, poison = %HTTPoison.Response{body: body}}, conn) do
        response = body |> Poison.decode!() |> build_response
        handle_ok_response(conn |> Credentials.new(), response)
      end

      # special handling for 'too many requests' status
      # in order to know when to retry
      def handle_response(
            {message, %HTTPoison.Response{status_code: 429, headers: headers}},
            conn
          ) do
        {retry_after, ""} =
          headers
          |> Enum.find(&(Kernel.elem(&1, 0) == "Retry-After"))
          |> Kernel.elem(1)
          |> Integer.parse()

        ApiFailure.new(conn, :rate_limit, retry_after)
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
    end
  end
end
