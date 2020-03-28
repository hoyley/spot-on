defmodule SpotOn.Model do
  @moduledoc """
  The Spotify context.
  """

  import Ecto.Query, warn: false
  alias SpotOn.SpotifyApi.Credentials
  alias SpotOn.Repo
  alias SpotOn.Model.User
  alias SpotOn.Model.UserTokens

  @doc """
  Returns the list of spotify_users.

  ## Examples

      iex> list_spotify_users()
      [%User{}, ...]

  """
  def list_spotify_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_name(name) do
    query = from u in User,
            where: u.name == ^name
    Repo.one(query)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(nil), do: create_user(%{})
  def create_user(attrs = %{}) when is_map(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end

  def create_user_by_name(name) do
    create_user(%{"name" => name})
  end

  def create_or_update_user(user) when is_map(user) do
    case get_user_by_name(user.name) do
      nil -> {:ok, create_user(user)}
      existing_user -> update_user(existing_user, user)
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def update_user_last_login(nil), do: nil

  def update_user_last_login(%User{} = user) do
    update_user_last_login(user, DateTime.utc_now())
  end

  def update_user_last_login(%User{} = user, last_login = %DateTime{}) do
    update_user(user, %{last_login: last_login})
  end

  def update_user_last_spotify_activity(%User{} = user) do
    update_user_last_spotify_activity(user, DateTime.utc_now())
  end

  def update_user_last_spotify_activity(%User{} = user, last_spotify_activity = %DateTime{}) do
    update_user(user, %{last_spotify_activity: last_spotify_activity})
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  alias SpotOn.Model.Follow

  @doc """
  Returns the list of follows.

  ## Examples

      iex> list_follows()
      [%Follow{}, ...]

  """
  def list_follows do
    Repo.all(Follow) |> Repo.preload([:leader_user, :follower_user])
  end

  @doc """
  Gets a single follow.

  Raises `Ecto.NoResultsError` if the Follow does not exist.

  ## Examples

      iex> get_follow!(123)
      %Follow{}

      iex> get_follow!(456)
      ** (Ecto.NoResultsError)

  """
  def get_follow!(id), do: Repo.get!(Follow, id) |> Repo.preload([:leader_user, :follower_user])

  def get_follow(leader_name, follower_name) do
    query = from f in Follow,
            join: lu in User, on: f.leader_user_id == lu.id,
            join: fu in User, on: f.follower_user_id == fu.id,
            where: lu.name == ^leader_name and fu.name == ^follower_name

    Repo.one(query) |> Repo.preload([:leader_user, :follower_user])
  end

  def get_follow_by_follower_name(follower_name) do
    query = from f in Follow,
                 join: fu in User, on: f.follower_user_id == fu.id,
                 where: fu.name == ^follower_name

    Repo.one(query) |> Repo.preload([:leader_user, :follower_user])
  end

  @doc """
  Creates a follow.

  ## Examples

      iex> create_follow(%{field: value})
      {:ok, %Follow{}}

      iex> create_follow(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_follow(attrs \\ %{}) do
    %Follow{}
    |> Follow.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a follow.

  ## Examples

      iex> update_follow(follow, %{field: new_value})
      {:ok, %Follow{}}

      iex> update_follow(follow, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_follow(%Follow{} = follow, attrs) do
    follow
    |> Follow.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a follow.

  ## Examples

      iex> delete_follow(follow)
      {:ok, %Follow{}}

      iex> delete_follow(follow)
      {:error, %Ecto.Changeset{}}

  """
  def delete_follow(%Follow{} = follow) do
    Repo.delete(follow)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking follow changes.

  ## Examples

      iex> change_follow(follow)
      %Ecto.Changeset{source: %Follow{}}

  """
  def change_follow(%Follow{} = follow) do
    Follow.changeset(follow, %{})
  end

  @doc """
  Returns the list of user_tokens.

  ## Examples

      iex> list_user_tokens()
      [%UserTokens{}, ...]

  """
  def list_user_tokens do
    Repo.all(UserTokens)
  end

  @doc """
  Gets a single user_tokens.

  Raises `Ecto.NoResultsError` if the User tokens does not exist.

  ## Examples

      iex> get_user_tokens!(123)
      %UserTokens{}

      iex> get_user_tokens!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_tokens!(id), do: Repo.get!(UserTokens, id)

  def get_user_token(user = %User{}) do
    query = from ut in UserTokens,
              where: ut.user_id == ^user.id
    Repo.one(query)
  end

  def get_user_token_by_user_name(user_name) do
    get_user_token(get_user_by_name(user_name))
  end

  def create_user_tokens(attrs \\ %{}) do
    %UserTokens{}
    |> UserTokens.changeset(attrs)
    |> Repo.insert!()
  end

  def create_or_update_user_tokens(%{id: id} = attrs) do
    create_or_update_user_tokens(id, attrs)
  end

  def create_or_update_user_tokens(user = %User{id: id}, creds = %Credentials{}) do
    change = creds
      |> Map.put_new(:user_id, id)
      |> Map.from_struct

    case get_user_token(user) do
      nil -> create_user_tokens(change)
      token -> update_user_tokens(token, change)
    end
  end

  def create_or_update_user_tokens(spotify_user_name, creds = %Credentials{}) when is_binary(spotify_user_name) do
    case get_user_by_name(spotify_user_name) do
      nil  -> create_user(spotify_user_name)
      user -> user
    end |> create_or_update_user_tokens(creds)
  end

  def create_or_update_user_tokens(spotify_user, conn = %Plug.Conn{}) do
    create_or_update_user_tokens(spotify_user, conn |> Credentials.new())
  end

  @doc """
  Updates a user_tokens.

  ## Examples

      iex> update_user_tokens(user_tokens, %{field: new_value})
      {:ok, %UserTokens{}}

      iex> update_user_tokens(user_tokens, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_tokens(%UserTokens{} = user_tokens, attrs) do
    user_tokens
    |> UserTokens.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_tokens.

  ## Examples

      iex> delete_user_tokens(user_tokens)
      {:ok, %UserTokens{}}

      iex> delete_user_tokens(user_tokens)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_tokens(%UserTokens{} = user_tokens) do
    Repo.delete(user_tokens)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_tokens changes.

  ## Examples

      iex> change_user_tokens(user_tokens)
      %Ecto.Changeset{source: %UserTokens{}}

  """
  def change_user_tokens(%UserTokens{} = user_tokens) do
    UserTokens.changeset(user_tokens, %{})
  end
end

