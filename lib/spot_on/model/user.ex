defmodule SpotOn.Model.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "spotify_users" do
    field :name, :string
    field :display_name, :string
    field :status, UserStatusEnum
    field :last_login, :utc_datetime
    field :last_spotify_activity, :utc_datetime
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :display_name, :status, :last_login, :last_spotify_activity])
    |> validate_required([:name, :display_name])
    |> unique_constraint(:name)
  end
end

defmodule SpotOn.Model.UserStatusEnum do
  use EctoEnum, type: :user_status_enum, enums: [:active, :revoked]
end
