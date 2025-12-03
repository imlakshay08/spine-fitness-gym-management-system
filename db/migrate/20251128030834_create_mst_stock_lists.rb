class CreateMstStockLists < ActiveRecord::Migration[7.1]
  def change
    create_table :mst_stock_lists do |t|

      t.timestamps
    end
  end
end
