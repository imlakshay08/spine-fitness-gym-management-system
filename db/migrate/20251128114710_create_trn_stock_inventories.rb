class CreateTrnStockInventories < ActiveRecord::Migration[7.1]
  def change
    create_table :trn_stock_inventories do |t|

      t.timestamps
    end
  end
end
