class AddPricingColumnsToMstMembershipPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :mst_membership_plans, :plan_duration_months, :integer, default: 0
    add_column :mst_membership_plans, :plan_mrp_amount,      :decimal, precision: 10, scale: 2, default: "0.0"
    add_column :mst_membership_plans, :plan_final_amount,    :decimal, precision: 10, scale: 2, default: "0.0"
  end
end
