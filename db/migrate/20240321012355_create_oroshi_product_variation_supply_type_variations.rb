class CreateOroshiProductVariationSupplyTypeVariations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_product_variation_supply_type_variations do |t|
      t.references :product_variation, null: false, foreign_key: { to_table: :oroshi_product_variations }
      t.references :supply_type_variation, null: false, foreign_key: { to_table: :oroshi_supply_type_variations }
      t.timestamps
    end
  end
end
