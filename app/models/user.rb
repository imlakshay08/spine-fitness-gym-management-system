class User < ApplicationRecord
  # Password storage lives here so login, change-password, admin reset and
  # user creation all share one implementation.
  #
  # Passwords were stored as unsalted MD5 (`userpassword`), which is not a
  # password hash: a leaked dump is reversed by looking every value up in a
  # rainbow table, not by cracking it. bcrypt is added *alongside* it so the
  # migration is invisible — each account is upgraded the next time its owner
  # logs in successfully, with no forced reset and no downtime.
  #
  # Every method degrades to the legacy path if the migration has not been run
  # yet, so the code and the schema can be deployed in either order.

  BCRYPT_COST = 12

  def self.bcrypt_ready?
    @bcrypt_ready = column_names.include?("using_bcrypt") && column_names.include?("password_digest") if @bcrypt_ready.nil?
    @bcrypt_ready
  end

  # True when `candidate` is this user's password, whichever scheme is in use.
  def authenticate_password(candidate)
    candidate = candidate.to_s
    return false if candidate.empty?

    if self.class.bcrypt_ready? && using_bcrypt?
      begin
        BCrypt::Password.new(password_digest.to_s) == candidate
      rescue BCrypt::Errors::InvalidHash
        false
      end
    else
      legacy_digest_matches?(candidate)
    end
  end

  # Verify, and transparently re-store as bcrypt if the account is still on MD5.
  def authenticate_and_upgrade(candidate)
    return false unless authenticate_password(candidate)

    upgrade_to_bcrypt(candidate) if self.class.bcrypt_ready? && !using_bcrypt?
    true
  end

  # Set a new password. Always written as bcrypt.
  def set_password(new_password)
    if self.class.bcrypt_ready?
      update(password_digest: BCrypt::Password.create(new_password.to_s, cost: BCRYPT_COST),
             using_bcrypt:    true,
             userpassword:    "")   # blank the legacy column
    else
      update(userpassword: Digest::MD5.hexdigest(new_password.to_s))
    end
  end

  # Attributes for building a brand-new user, for the callers that construct
  # a User rather than updating one.
  def self.password_attributes(new_password)
    if bcrypt_ready?
      { password_digest: BCrypt::Password.create(new_password.to_s, cost: BCRYPT_COST),
        using_bcrypt:    true,
        userpassword:    "" }
    else
      { userpassword: Digest::MD5.hexdigest(new_password.to_s) }
    end
  end

  # The value stashed in session[:SECURED_LOGIN_CHK] and re-checked on every
  # request. It must be whatever the column actually holds now.
  def secured_login_check_value
    (self.class.bcrypt_ready? && using_bcrypt?) ? password_digest.to_s : userpassword.to_s
  end

  private

  def legacy_digest_matches?(candidate)
    stored = userpassword.to_s
    return false if stored.empty?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::MD5.hexdigest(candidate), stored
    )
  rescue ArgumentError   # different lengths — not a match
    false
  end

  def upgrade_to_bcrypt(plaintext)
    update_columns(
      password_digest: BCrypt::Password.create(plaintext, cost: BCRYPT_COST),
      using_bcrypt:    true,
      userpassword:    ""
    )
  end
end
