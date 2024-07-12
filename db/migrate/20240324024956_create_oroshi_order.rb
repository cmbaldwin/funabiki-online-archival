class CreateOroshiOrder < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_orders do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :oroshi_buyers }
      t.references :product_variation, null: false, foreign_key: { to_table: :oroshi_product_variations }
      t.references :product_inventory, null: false, foreign_key: { to_table: :oroshi_product_inventories }
      t.references :shipping_receptacle, null: false, foreign_key: { to_table: :oroshi_shipping_receptacles }
      t.references :shipping_method, null: false, foreign_key: { to_table: :oroshi_shipping_methods }
      t.integer :item_quantity, null: false, default: 0
      t.integer :receptacle_quantity, null: false, default: 0
      t.integer :freight_quantity, null: false, default: 0
      t.float :shipping_cost, null: false, default: 0
      t.float :materials_cost, null: false, default: 0
      t.float :sale_price_per_item, null: false, default: 0
      t.float :adjustment, null: false, default: 0
      t.string :note
      t.integer :status
      t.references :bundled_with_order, null: true, foreign_key: { to_table: :oroshi_orders }
      t.boolean :bundled_shipping_receptacle, default: false
      t.boolean :add_buyer_optional_cost, default: false
      t.date :shipping_date
      t.date :arrival_date
      t.timestamps
    end
  end
end
