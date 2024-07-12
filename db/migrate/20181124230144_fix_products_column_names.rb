class FixProductsColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :products, :excost, :cost
    rename_column :products, :ptype, :product_type
    rename_column :products, :multipl, :multiplier
    add_column :products, :extra_expense, :decimal
  end
end
