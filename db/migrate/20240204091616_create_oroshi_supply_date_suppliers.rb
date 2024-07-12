class CreateOroshiSupplyDateSuppliers < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_date_suppliers do |t|
      t.references :supply_date, null: false, foreign_key: { to_table: :oroshi_supply_dates }
      t.references :supplier, null: false, foreign_key: { to_table: :oroshi_suppliers }
      t.timestamps
    end

    add_index :oroshi_supply_date_suppliers, [:supply_date_id, :supplier_id], unique: true, name: 'index_supply_date_suppliers_on_ids'
    add_index :oroshi_supply_date_suppliers, [:supplier_id, :supply_date_id], name: 'index_suppliers_supply_dates_on_ids'
  end
end
