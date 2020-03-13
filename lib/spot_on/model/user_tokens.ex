defmodule SpotOn.Model.UserTokens do
  use Ecto.Schema
  import Ecto.Changeset
  alias SpotOn.Model.User

  schema "spotify_user_tokens" do
    belongs_to :user, User
    field :access_token, :string
    field :refresh_token, :string

    timestamps()
  end

  @doc false
  def changeset(user_tokens, attrs) do
    user_tokens
    |> cast(attrs, [:user_id, :access_token, :refresh_token])
    |> validate_required([:user_id, :access_token, :refresh_token])
    |> unique_constraint(:user_id)
  end
end
