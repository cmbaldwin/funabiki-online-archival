class CreateOroshiProductVariations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_product_variations do |t|
      t.references :product, null: false, foreign_key: { to_table: :oroshi_products }
      t.references :default_shipping_receptacle, foreign_key: { to_table: :oroshi_shipping_receptacles }
      t.string :name, null: false
      t.string :handle, null: false
      t.float :primary_content_volume, null: false
      t.integer :primary_content_country_id
      t.integer :primary_content_subregion_id
      t.integer :shelf_life
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
