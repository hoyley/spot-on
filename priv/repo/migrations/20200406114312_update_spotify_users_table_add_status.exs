defmodule SpotOn.Repo.Migrations.UpdateSpotifyUsersTable do
  use Ecto.Migration
  alias SpotOn.Model.UserStatusEnum

  def up do
    UserStatusEnum.create_type()
  end

  def down do
    UserStatusEnum.drop_type()
  end

  def change do
    alter table(:spotify_users) do
      add :status, UserStatusEnum.type(), null: false, default: "active"
    end
  end
end
