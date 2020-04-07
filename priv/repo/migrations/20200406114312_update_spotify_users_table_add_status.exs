defmodule SpotOn.Repo.Migrations.UpdateSpotifyUsersTable do
  use Ecto.Migration
  alias SpotOn.Model.UserStatusEnum

  def change do
    UserStatusEnum.create_type()

    alter table(:spotify_users) do
      add :status, UserStatusEnum.type(), null: false, default: "active"
    end
  end
end
