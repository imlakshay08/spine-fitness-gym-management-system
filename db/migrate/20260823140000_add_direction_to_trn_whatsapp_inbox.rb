class AddDirectionToTrnWhatsappInbox < ActiveRecord::Migration[7.1]
  TABLE = :trn_whatsapp_inbox

  def up
    # Outgoing messages used to be squeezed onto the inbound row they answered
    # (wi_reply_text), so a thread could hold only one reply and it had no place
    # of its own in the timeline. Each message now gets its own row.
    add_column TABLE, :wi_direction, :string, limit: 3, default: 'IN', null: false unless column_exists?(TABLE, :wi_direction)
    add_column TABLE, :wi_status,    :string, limit: 20                            unless column_exists?(TABLE, :wi_status)
    add_column TABLE, :wi_seen_at,   :datetime, precision: nil                     unless column_exists?(TABLE, :wi_seen_at)
    add_column TABLE, :wi_error,     :string, limit: 250                           unless column_exists?(TABLE, :wi_error)

    execute "UPDATE trn_whatsapp_inbox SET wi_direction = 'IN' WHERE wi_direction IS NULL OR wi_direction = ''"
    # Anything already answered counts as read, so historic threads don't light
    # up the sidebar the first time the new inbox loads.
    execute "UPDATE trn_whatsapp_inbox SET wi_seen_at = wi_replied_at WHERE wi_replied = 1 AND wi_seen_at IS NULL"
  end

  def down
    remove_column TABLE, :wi_direction if column_exists?(TABLE, :wi_direction)
    remove_column TABLE, :wi_status    if column_exists?(TABLE, :wi_status)
    remove_column TABLE, :wi_seen_at   if column_exists?(TABLE, :wi_seen_at)
    remove_column TABLE, :wi_error     if column_exists?(TABLE, :wi_error)
  end
end
