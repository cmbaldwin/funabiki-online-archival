class CreateOroshiProductInventory < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_product_inventories do |t|
      t.references :product_variation, null: false, foreign_key: { to_table: :oroshi_product_variations }
      t.date :manufacture_date, null: false
      t.date :expiration_date, null: false
      t.integer :quantity, null: false, default: 0
      t.timestamps
    end
  end
end
