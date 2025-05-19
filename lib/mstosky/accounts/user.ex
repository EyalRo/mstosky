defmodule Mstosky.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bcrypt, as: BcryptElixir

  schema "users" do
    field :email, :string
    field :username, :string
    field :display_name, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :admin, :boolean, default: false
    # Federated/external user support
    field :provider, :string
    field :provider_uid, :string
    field :avatar_url, :string
    field :external, :boolean, default: false
    # Fake user metadata
    field :fake, :boolean, default: false
    field :fake_source, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Finds or creates a user for a federated/external provider (e.g., Mastodon, Bluesky).
  """
  def get_or_create_external_user(attrs) do
    import Ecto.Query
    alias Mstosky.Repo

    cond do
      # Federated/external user: must have provider and provider_uid, and neither nil
      Map.has_key?(attrs, "provider") and Map.has_key?(attrs, "provider_uid") and
        not is_nil(attrs["provider"]) and not is_nil(attrs["provider_uid"]) ->
        provider = attrs["provider"]
        provider_uid = attrs["provider_uid"]

        user =
          Repo.one(
            from u in __MODULE__,
              where: u.provider == ^provider and u.provider_uid == ^provider_uid
          )

        if user do
          user
        else
          # Ensure federated users have email and password
          attrs =
            attrs
            |> Map.put_new(
              "email",
              "#{Base.encode16(:crypto.strong_rand_bytes(8))}@federated.local"
            )
            |> Map.put_new("password", Base.encode16(:crypto.strong_rand_bytes(8)))

          registration_changeset(%__MODULE__{}, attrs)
          |> Repo.insert!(on_conflict: :nothing, conflict_target: [:provider, :provider_uid])
        end

      # Local user: no provider/provider_uid or either is nil
      true ->
        email = Map.fetch!(attrs, "email")
        user = Repo.one(from u in __MODULE__, where: u.email == ^email)

        if user do
          user
        else
          registration_changeset(%__MODULE__{}, attrs)
          |> Repo.insert!(on_conflict: :nothing, conflict_target: [:email])
        end
    end
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    avatar_url =
      case Map.get(attrs, "avatar_url") do
        nil -> Faker.Avatar.image_url()
        "" -> Faker.Avatar.image_url()
        url -> url
      end

    attrs = Map.put(attrs, "avatar_url", avatar_url)

    user
    |> cast(attrs, [
      :email,
      :username,
      :password,
      :display_name,
      :provider,
      :provider_uid,
      :avatar_url,
      :external,
      :fake,
      :fake_source
    ])
    |> validate_email(opts)
    |> validate_username(opts)
    |> validate_password(opts)
  end

  defp validate_username(changeset, _opts) do
    provider = get_field(changeset, :provider)
    _username = get_field(changeset, :username)

    cond do
      is_nil(provider) ->
        changeset
        |> validate_required([:username])
        |> validate_length(:username, min: 3, max: 32)
        |> unsafe_validate_unique(:username, Mstosky.Repo)
        |> unique_constraint(:username)

      true ->
        changeset
    end
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, BcryptElixir.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Mstosky.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Mstosky.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    BcryptElixir.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    BcryptElixir.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
