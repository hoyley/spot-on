defmodule SpotOn.Repo.Migrations.CreateUserStatusEnumType do
  use Ecto.Migration
  alias SpotOn.Model.UserStatusEnum

  def up do
    UserStatusEnum.create_type()
  end

  def down do
    UserStatusEnum.drop_type()
  end
end
