class AddAveragePriceToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :average_price, :decimal
  end
end
