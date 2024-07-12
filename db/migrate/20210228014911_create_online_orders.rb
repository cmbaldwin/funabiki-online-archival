class CreateOnlineOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :online_orders do |t|
      t.bigint :order_id
      t.datetime :order_time
      t.datetime :date_modified
      t.string :status
      t.date :ship_date
      t.date :arrival_date
      t.text :data

      t.timestamps
    end
  end
end
