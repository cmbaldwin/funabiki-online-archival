class CreateOroshiSupplyDateSupplyTypeVariations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_date_supply_type_variations do |t|
      t.references :supply_date, null: false, foreign_key: { to_table: :oroshi_supply_dates }
      t.references :supply_type_variation, null: false, foreign_key: { to_table: :oroshi_supply_type_variations }
      t.integer :total, default: 0
      t.timestamps
    end
    add_index :oroshi_supply_date_supply_type_variations, [:supply_date_id, :supply_type_variation_id], unique: true, name: 'index_supply_date_supply_type_variations_on_ids'
    add_index :oroshi_supply_date_supply_type_variations, [:supply_type_variation_id, :supply_date_id], name: 'index_supply_type_variations_supply_dates_on_ids'
  end
end
