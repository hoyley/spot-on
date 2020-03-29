defmodule SpotOn.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:spotify_follows) do
      add :leader_user_id, references(:spotify_users, on_delete: :nothing), null: false
      add :follower_user_id, references(:spotify_users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:spotify_follows, [:leader_user_id])
    create index(:spotify_follows, [:follower_user_id])

    create unique_index(:spotify_follows, [:leader_user_id, :follower_user_id],
             name: :unique_leader_follower
           )
  end
end
