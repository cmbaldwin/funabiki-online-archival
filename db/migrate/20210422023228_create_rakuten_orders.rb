class CreateRakutenOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :rakuten_orders do |t|
      t.string :order_id
      t.datetime :order_time
      t.date :arrival_date
      t.text :ship_dates, array: true, default: []
      t.integer :status
      t.text :data

      t.timestamps
    end
  end
end
