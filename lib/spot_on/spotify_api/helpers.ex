# This file has been copied and modified from [https://github.com/jsncmgs1/spotify_ex].
# The repository is not used as a library because it doesn't support mocking of the API level.
defmodule Helpers do
  @moduledoc false

  def query_string(nil), do: ""
  def query_string([]), do: ""
  def query_string(params), do: "?" <> URI.encode_query(params)

  @doc """
  Converts a map of string keys to a map of atoms and turns it into a struct
  """
  def to_struct(kind, attrs) do
    struct = struct(kind)

    struct
    |> Map.to_list()
    |> Enum.reduce(struct, fn {key, _}, acc ->
      result = Map.fetch(attrs, Atom.to_string(key))

      case result do
        {:ok, value} -> %{acc | key => value}
        :error -> acc
      end
    end)
  end
end
