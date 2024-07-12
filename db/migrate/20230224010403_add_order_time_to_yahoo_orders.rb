class AddOrderTimeToYahooOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :yahoo_orders, :order_time, :datetime
  end
end
