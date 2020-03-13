defmodule SpotOn.Repo.Migrations.CreateUserTokens do
  use Ecto.Migration

  def change do
    create table(:spotify_user_tokens) do
      add :user_id, references(:spotify_users, on_delete: :nothing)
      add :access_token, :string
      add :refresh_token, :string

      timestamps()
    end

    create unique_index(:spotify_user_tokens, [:user_id])
  end
end
