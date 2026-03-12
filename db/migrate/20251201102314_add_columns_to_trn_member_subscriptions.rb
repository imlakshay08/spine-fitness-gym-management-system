class AddColumnsToTrnMemberSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :trn_member_subscriptions, :ms_compcode,        :string,  limit: 12,  default: "", null: false
    add_column :trn_member_subscriptions, :ms_sbscrptn_no,     :string,  limit: 15,  default: "", null: false
    add_column :trn_member_subscriptions, :ms_member_id,       :integer,             default: 0,  null: false
    add_column :trn_member_subscriptions, :ms_plan_id,         :integer,             default: 0,  null: false
    add_column :trn_member_subscriptions, :ms_plan_amount,     :decimal, precision: 10, scale: 2, default: "0.0"
    add_column :trn_member_subscriptions, :ms_final_amount,    :decimal, precision: 10, scale: 2, default: "0.0"
    add_column :trn_member_subscriptions, :ms_discount_amount, :decimal, precision: 10, scale: 2, default: "0.0"
    add_column :trn_member_subscriptions, :ms_start_date,      :date
    add_column :trn_member_subscriptions, :ms_end_date,        :date
    add_column :trn_member_subscriptions, :ms_amount_paid,     :decimal, precision: 10, scale: 2, default: "0.0"
    add_column :trn_member_subscriptions, :ms_payment_mode,    :string,  limit: 20,  default: ""
    add_column :trn_member_subscriptions, :ms_status,          :string,  limit: 10,  default: "ACTIVE"
    add_column :trn_member_subscriptions, :ms_remarks,         :string,  limit: 200, default: ""
  end
end
