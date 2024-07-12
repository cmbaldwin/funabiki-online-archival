class AddFrozenMemoNameAndExtraShippingCostToEcProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :ec_products, :frozen, :boolean
    add_column :ec_products, :memo_name, :string
    add_column :ec_products, :extra_shipping_cost, :integer
  end
end
