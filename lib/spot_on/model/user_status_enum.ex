defmodule SpotOn.Model.UserStatusEnum do
  use EctoEnum, type: :user_status_enum, enums: [:active, :revoked]
end
