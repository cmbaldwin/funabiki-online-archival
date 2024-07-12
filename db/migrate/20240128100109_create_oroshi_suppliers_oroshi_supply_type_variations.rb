class CreateOroshiSuppliersOroshiSupplyTypeVariations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_suppliers_oroshi_supply_type_variations do |t|
      t.references :supplier, null: false, foreign_key: { to_table: :oroshi_suppliers }
      t.references :supply_type_variation, null: false, foreign_key: { to_table: :oroshi_supply_type_variations }
      t.timestamps
    end
  end
end
