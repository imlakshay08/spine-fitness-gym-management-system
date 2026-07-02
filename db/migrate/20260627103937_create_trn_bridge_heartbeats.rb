class CreateTrnBridgeHeartbeats < ActiveRecord::Migration[7.1]
  def change
    create_table :trn_bridge_heartbeats do |t|

      t.timestamps
    end
  end
end
