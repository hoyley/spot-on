defmodule SpotOn.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create unique_index(:spotify_follows, [:follower_user_id], name: :unique_follower)
  end
end
