class AddProfitableToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :profitable, :boolean
  end
end
