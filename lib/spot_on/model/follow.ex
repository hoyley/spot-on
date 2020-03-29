defmodule SpotOn.Model.Follow do
  use Ecto.Schema
  import Ecto.Changeset
  alias SpotOn.Model.User

  schema "spotify_follows" do
    belongs_to :leader_user, User, foreign_key: :leader_user_id
    belongs_to :follower_user, User, foreign_key: :follower_user_id

    timestamps()
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:leader_user_id, :follower_user_id])
    |> validate_required([:leader_user_id, :follower_user_id])
    |> unique_constraint(:unique_constraint_leader_follower,
      name: :unique_leader_follower
    )
  end
end
