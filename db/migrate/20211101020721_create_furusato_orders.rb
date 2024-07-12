class CreateFurusatoOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :furusato_orders do |t|
      t.integer :ssys_id
      t.string :furusato_id
      t.string :katakana_name
      t.string :kanji_name
      t.string :title
      t.string :product_code
      t.string :product_name
      t.string :order_status
      t.date :system_entry_date
      t.date :shipped_date
      t.date :est_arrival_date
      t.date :est_shipping_date
      t.string :arrival_time
      t.string :shipping_company
      t.string :shipping_number
      t.string :details_url
      t.string :address
      t.string :phone
      t.string :sale_memo
      t.string :mail_memo
      t.string :lead_time
      t.string :noshi

      t.timestamps
    end
  end
end
