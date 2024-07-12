class CreateOroshiProductVariationPackagings < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_product_variation_packagings do |t|
      t.references :product_variation, null: false, foreign_key: { to_table: :oroshi_product_variations }
      t.references :packaging, null: false, foreign_key: { to_table: :oroshi_packagings }
      t.timestamps
    end
  end
end
