class CreateTrnWhatsappLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :trn_whatsapp_logs, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.string   :wl_compcode,        limit: 12,  default: ""
      t.integer  :wl_member_id
      t.integer  :wl_subscription_id
      t.string   :wl_template_name,   limit: 60
      t.string   :wl_status,          limit: 15,  default: "QUEUED"
      t.datetime :wl_sent_at
      t.datetime :wl_delivered_at
      t.datetime :wl_read_at
      t.string   :wl_interakt_msg_id, limit: 100
      t.text     :wl_api_response
      t.text     :wl_failed_reason

      t.timestamps
    end

    add_index :trn_whatsapp_logs, :wl_interakt_msg_id
    add_index :trn_whatsapp_logs, [:wl_subscription_id, :wl_template_name, :wl_status], name: "idx_whatsapp_logs_sub_template_status"
  end
end
