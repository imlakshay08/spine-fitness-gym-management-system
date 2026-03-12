class CreateTrnPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :trn_payments, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.string  :pay_compcode,  limit: 12,  default: "", null: false
      t.string  :pay_no,        limit: 15,  default: "", null: false
      t.string  :pay_ref_type,  limit: 30,  default: ""
      t.integer :pay_ref_id
      t.date    :pay_date
      t.decimal :pay_amount,    precision: 10, scale: 2, default: "0.0"
      t.string  :pay_mode,      limit: 20,  default: ""
      t.string  :pay_remarks,   limit: 200, default: ""

      t.timestamps
    end

    add_index :trn_payments, :pay_no
  end
end
