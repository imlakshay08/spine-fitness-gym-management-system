class AddMessageBodyToTrnWhatsappLogs < ActiveRecord::Migration[7.1]
  def change
    # Snapshot of the exact WhatsApp text delivered to the member, captured at
    # send time. Old rows (before this column existed) fall back to a rebuilt
    # message in the UI; new rows read straight from here so the log always
    # shows what was actually sent even if the subscription is later renewed.
    add_column :trn_whatsapp_logs, :wl_message_body, :text
  end
end
