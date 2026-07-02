class CreateBiometricIdAllocations < ActiveRecord::Migration[7.1]
  def change
    create_table :biometric_id_allocations do |t|

      t.timestamps
    end
  end
end
