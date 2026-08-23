class AddStatusToMstMembersLists < ActiveRecord::Migration[7.1]
  TABLE = :mst_members_lists

  def up
    # Staff need the member list free of people who have left, but the
    # subscriptions and payments those people made must keep resolving to a
    # name. Deleting the row breaks that; flagging it does not.
    #   A = on roll, R = removed
    add_column TABLE, :mmbr_status,        :string, limit: 1, default: 'A', null: false unless column_exists?(TABLE, :mmbr_status)
    add_column TABLE, :mmbr_removed_at,    :datetime, precision: nil                    unless column_exists?(TABLE, :mmbr_removed_at)
    add_column TABLE, :mmbr_removed_by,    :string, limit: 50                           unless column_exists?(TABLE, :mmbr_removed_by)
    add_column TABLE, :mmbr_remove_reason, :string, limit: 250                          unless column_exists?(TABLE, :mmbr_remove_reason)

    execute "UPDATE mst_members_lists SET mmbr_status = 'A' WHERE mmbr_status IS NULL OR mmbr_status = ''"

    unless index_exists?(TABLE, [:mmbr_compcode, :mmbr_status], name: 'idx_members_compcode_status')
      add_index TABLE, [:mmbr_compcode, :mmbr_status], name: 'idx_members_compcode_status'
    end
  end

  def down
    remove_index  TABLE, name: 'idx_members_compcode_status' if index_exists?(TABLE, [:mmbr_compcode, :mmbr_status], name: 'idx_members_compcode_status')
    remove_column TABLE, :mmbr_status        if column_exists?(TABLE, :mmbr_status)
    remove_column TABLE, :mmbr_removed_at    if column_exists?(TABLE, :mmbr_removed_at)
    remove_column TABLE, :mmbr_removed_by    if column_exists?(TABLE, :mmbr_removed_by)
    remove_column TABLE, :mmbr_remove_reason if column_exists?(TABLE, :mmbr_remove_reason)
  end
end
