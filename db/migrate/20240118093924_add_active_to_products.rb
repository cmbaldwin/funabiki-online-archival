class AddActiveToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :active, :boolean, default: true

    Product.update_all(active: true)
  end
end
