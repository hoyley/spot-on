defmodule SpotOn.SpotifyApi.ApiFailure do
  alias SpotOn.SpotifyApi.ApiFailure

  defstruct message: nil,
    status: nil

  def new(message, status) do
    %ApiFailure{ message: message, status: status }
  end

  def new(message) do
    %ApiFailure{ message: message }
  end

  def wrap({:ok, %{"error" => %{"message" => error_message, "status" => error_status}}}) do
    new(error_message, error_status)
  end

  def wrap({:error, message}) do
    new(message)
  end
  
  def wrap(response), do: response
end
