class CreateOroshiProductMaterials < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_product_materials do |t|
      t.references :product, null: false, foreign_key: { to_table: :oroshi_products }
      t.references :material, null: false, foreign_key: { to_table: :oroshi_materials }
      t.timestamps
    end
  end
end
