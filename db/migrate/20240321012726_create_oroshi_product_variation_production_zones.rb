class CreateOroshiProductVariationProductionZones < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_product_variation_production_zones do |t|
      t.references :product_variation, null: false, foreign_key: { to_table: :oroshi_product_variations }
      t.references :production_zone, null: false, foreign_key: { to_table: :oroshi_production_zones }
      t.timestamps
    end
  end
end
