class CreateTrnMemberSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :trn_member_subscriptions do |t|

      t.timestamps
    end
  end
end
