class AddDefaultPerBoxToOroshiProductVariations < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_product_variations, :default_per_box, :integer
  end
end
