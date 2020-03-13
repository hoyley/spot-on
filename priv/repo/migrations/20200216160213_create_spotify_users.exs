defmodule SpotOn.Repo.Migrations.CreateSpotifyUsers do
  use Ecto.Migration

  def change do
    create table(:spotify_users) do
      add :name, :string

      timestamps()
    end

    create unique_index(:spotify_users, [:name])
  end
end
