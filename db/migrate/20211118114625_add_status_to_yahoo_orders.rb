class AddStatusToYahooOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :yahoo_orders, :order_status, :string
    add_column :yahoo_orders, :shipping_status, :string
  end
end
