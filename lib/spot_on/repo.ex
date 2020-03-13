defmodule SpotOn.Repo do
  use Ecto.Repo,
    otp_app: :spot_on,
    adapter: Ecto.Adapters.Postgres

  def init(_, config) do
    config = config
             |> set_if_exists(:username, System.get_env("PGUSER"))
             |> set_if_exists(:password, System.get_env("PGPASSWORD"))
             |> set_if_exists(:database, System.get_env("PGDATABASE"))
             |> set_if_exists(:hostname, System.get_env("PGHOST"))
             |> set_int_if_exists(:port, System.get_env("PGPORT"))
    {:ok, config}
  end

  defp set_if_exists(config, _env_symbol, nil), do: config
  defp set_if_exists(config, env_symbol, env_value) do
    Keyword.put(config, env_symbol, env_value)
  end
  defp set_int_if_exists(config, _env_symbol, nil), do: config
  defp set_int_if_exists(config, env_symbol, env_value) do
    Keyword.put(config, env_symbol, env_value |> String.to_integer)
  end

end
