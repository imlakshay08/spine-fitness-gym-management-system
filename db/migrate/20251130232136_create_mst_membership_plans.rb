class CreateMstMembershipPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :mst_membership_plans do |t|

      t.timestamps
    end
  end
end
