defmodule SpotOn.SpotifyApi.ApiSuccess do
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Credentials

  defstruct result: nil,
            credentials: nil

  def new(result, credentials = %Credentials{}) do
    %ApiSuccess{result: result, credentials: credentials}
  end
end
