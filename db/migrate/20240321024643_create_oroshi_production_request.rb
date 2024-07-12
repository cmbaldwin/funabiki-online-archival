class CreateOroshiProductionRequest < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_production_requests do |t|
      t.references :product_variation, null: false, foreign_key: { to_table: :oroshi_product_variations }
      t.references :product_inventory, foreign_key: { to_table: :oroshi_product_inventories }
      t.references :production_zone, null: false, foreign_key: { to_table: :oroshi_production_zones }
      t.references :shipping_receptacle, foreign_key: { to_table: :oroshi_shipping_receptacles }
      t.integer :request_quantity, null: false
      t.integer :fulfilled_quantity, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.timestamps
    end
  end
end
