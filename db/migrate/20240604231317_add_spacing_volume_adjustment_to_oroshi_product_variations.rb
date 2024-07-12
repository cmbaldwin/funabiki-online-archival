class AddSpacingVolumeAdjustmentToOroshiProductVariations < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_product_variations, :spacing_volume_adjustment, :decimal, precision: 5, scale: 2, default: 1.0
  end
end
