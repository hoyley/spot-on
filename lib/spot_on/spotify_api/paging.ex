# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule Paging do
  @moduledoc """
  Spotify wraps collections in a paging object in order to handle pagination.
  Requesting a collection will send the collection back in the `items` key,
  along with the paging links.
  """

  import Helpers

  @doc """
  Paging Struct. The Spotify API returns collections in a Paging
  object, with the collection in the `items` key.
  """
  defstruct ~w[href items limit next offset previous total cursors]a

  @doc """
    Takes the response body from an API call that returns a collection.
    Param items should be structs from that collections types, for example
    getting a collection playlists, items should be [%Spotify.Playlist{}, ...]
    Replaces the map currently items with the collection.

    Not every collection is wrapped in a paging object.
  """
  def response(body, items) do
    to_struct(__MODULE__, body) |> Map.put(:items, items)
  end
end
