class CreateInfomartOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :infomart_orders do |t|
      t.bigint :order_id
      t.string :status
      t.string :destination
      t.datetime :order_time
      t.date :ship_date
      t.date :arrival_date
      t.text :items
      t.string :address
      t.text :csv_data

      t.timestamps
    end
  end
end
