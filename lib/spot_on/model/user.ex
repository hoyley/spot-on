defmodule SpotOn.Model.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "spotify_users" do
    field :name, :string
    field :display_name, :string
    field :last_login, :utc_datetime
    field :last_spotify_activity, :utc_datetime
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :display_name, :last_login, :last_spotify_activity])
    |> validate_required([:name, :display_name])
    |> unique_constraint(:name)
  end
end
