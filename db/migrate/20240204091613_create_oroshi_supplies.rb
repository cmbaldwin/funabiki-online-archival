class CreateOroshiSupplies < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supplies do |t|
      t.references :supply_type_variation, null: false, foreign_key: { to_table: :oroshi_supply_type_variations }
      t.references :supply_reception_time, null: false, foreign_key: { to_table: :oroshi_supply_reception_times }
      t.references :supplier, null: false, foreign_key: { to_table: :oroshi_suppliers }
      t.references :supply_date, null: false, foreign_key: { to_table: :oroshi_supply_dates }
      t.boolean :locked, default: false
      t.float :quantity, null: false, default: 0
      t.float :price, null: false, default: 0

      t.timestamps
    end
  end
end
