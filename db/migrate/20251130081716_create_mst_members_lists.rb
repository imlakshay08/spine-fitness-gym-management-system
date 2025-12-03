class CreateMstMembersLists < ActiveRecord::Migration[7.1]
  def change
    create_table :mst_members_lists do |t|

      t.timestamps
    end
  end
end
