class AddReactionToTrnWhatsappInbox < ActiveRecord::Migration[7.1]
  TABLE = :trn_whatsapp_inbox

  def up
    # A WhatsApp reaction is not a message of its own — it is an emoji stuck to
    # an existing message. Storing which message it belongs to is what lets the
    # inbox render it the way WhatsApp does instead of as an empty bubble.
    add_column TABLE, :wi_reaction_to, :string, limit: 200 unless column_exists?(TABLE, :wi_reaction_to)

    unless index_exists?(TABLE, :wi_reaction_to, name: 'idx_wa_inbox_reaction_to')
      add_index TABLE, :wi_reaction_to, name: 'idx_wa_inbox_reaction_to'
    end
  end

  def down
    remove_index  TABLE, name: 'idx_wa_inbox_reaction_to' if index_exists?(TABLE, :wi_reaction_to, name: 'idx_wa_inbox_reaction_to')
    remove_column TABLE, :wi_reaction_to if column_exists?(TABLE, :wi_reaction_to)
  end
end
