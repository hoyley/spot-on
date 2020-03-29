defmodule SpotOn.Repo.Migrations.UpdateSpotifyUsersTable do
  use Ecto.Migration

  def change do
    alter table(:spotify_users) do
      add :last_login, :utc_datetime, null: false, default: fragment("now()")
      add :last_spotify_activity, :utc_datetime, null: false, default: fragment("now()")
    end
  end
end
