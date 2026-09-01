class AddBcryptColumnsToUsers < ActiveRecord::Migration[7.1]
  def change
    # Added alongside the legacy MD5 `userpassword` column, not replacing it.
    # Every user is upgraded silently on their next successful login, so no
    # password reset and no downtime. `userpassword` stays as the rollback
    # path until every active user shows using_bcrypt = 1.
    add_column :users, :password_digest, :string,  limit: 100 unless column_exists?(:users, :password_digest)
    add_column :users, :using_bcrypt,    :boolean, default: false, null: false unless column_exists?(:users, :using_bcrypt)
  end
end
