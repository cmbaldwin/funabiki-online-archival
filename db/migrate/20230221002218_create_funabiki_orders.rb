class CreateFunabikiOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :funabiki_orders do |t|
      t.string :order_id
      t.datetime :order_time
      t.date :ship_date
      t.date :arrival_date
      t.string :ship_status
      t.json :data

      t.timestamps
    end
  end
end
