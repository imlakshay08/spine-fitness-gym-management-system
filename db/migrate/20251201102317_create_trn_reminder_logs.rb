class CreateTrnReminderLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :trn_reminder_logs do |t|
      t.integer :member_id,       null: false
      t.integer :subscription_id, null: false

      t.timestamps
    end

    add_index :trn_reminder_logs, [:member_id, :subscription_id], unique: true
  end
end
