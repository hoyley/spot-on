defmodule SpotOn.Repo.Migrations.UpdateSpotifyUsersTableAddStatus do
  use Ecto.Migration
  alias SpotOn.Model.UserStatusEnum

  def change do
    alter table(:spotify_users) do
      add :status, UserStatusEnum.type(), null: false, default: "active"
    end
  end
end
