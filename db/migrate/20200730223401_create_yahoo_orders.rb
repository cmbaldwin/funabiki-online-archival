class CreateYahooOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :yahoo_orders do |t|
      t.string :order_id
      t.date :ship_date
      t.text :details

      t.timestamps
    end
  end
end
