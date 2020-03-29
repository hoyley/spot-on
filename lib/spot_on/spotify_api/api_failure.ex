defmodule SpotOn.SpotifyApi.ApiFailure do
  alias SpotOn.SpotifyApi.ApiFailure
  alias SpotOn.SpotifyApi.Credentials

  defstruct message: nil,
            status: nil,
            credentials: nil

  def new(message, status, credentials = %Credentials{}) do
    %ApiFailure{message: message, status: status, credentials: credentials}
  end
end
