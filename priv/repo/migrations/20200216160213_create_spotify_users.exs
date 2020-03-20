defmodule SpotOn.Repo.Migrations.CreateSpotifyUsers do
  use Ecto.Migration

  def change do
    create table(:spotify_users) do
      add :name, :string, null: false
      add :display_name, :string, null: false
      timestamps()
    end

    create unique_index(:spotify_users, [:name])
  end
end
