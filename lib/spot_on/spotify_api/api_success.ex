defmodule SpotOn.SpotifyApi.ApiSuccess do
  alias SpotOn.SpotifyApi.ApiSuccess
  alias SpotOn.SpotifyApi.Credentials

  defstruct result: nil,
            credentials: nil

  def new(credentials = %Credentials{}, result) do
    %ApiSuccess{result: result, credentials: credentials}
  end

  def new(credentials = %Credentials{}) do
    %ApiSuccess{credentials: credentials}
  end
end
