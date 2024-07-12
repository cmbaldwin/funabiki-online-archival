class CreateOroshiSupplyDateSupplyTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_date_supply_types do |t|
      t.references :supply_date, null: false, foreign_key: { to_table: :oroshi_supply_dates }
      t.references :supply_type, null: false, foreign_key: { to_table: :oroshi_supply_types }
      t.integer :total, default: 0
      t.timestamps
    end
    add_index :oroshi_supply_date_supply_types, [:supply_date_id, :supply_type_id], unique: true, name: 'index_supply_date_supply_types_on_ids'
    add_index :oroshi_supply_date_supply_types, [:supply_type_id, :supply_date_id], name: 'index_supply_types_supply_dates_on_ids'
  end
end
