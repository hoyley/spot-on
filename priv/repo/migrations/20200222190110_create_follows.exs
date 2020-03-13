defmodule SpotOn.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:spotify_follows) do
      add :leader_user_id, references(:spotify_users, on_delete: :nothing)
      add :follower_user_id, references(:spotify_users, on_delete: :nothing)

      timestamps()
    end

    create index(:spotify_follows, [:leader_user_id])
    create index(:spotify_follows, [:follower_user_id])
  end
end
