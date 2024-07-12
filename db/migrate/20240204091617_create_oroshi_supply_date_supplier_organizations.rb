class CreateOroshiSupplyDateSupplierOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_date_supplier_organizations do |t|
      t.references :supply_date, null: false, foreign_key: { to_table: :oroshi_supply_dates }
      t.references :supplier_organization, null: false, foreign_key: { to_table: :oroshi_supplier_organizations }
      t.timestamps
    end
    add_index :oroshi_supply_date_supplier_organizations, [:supply_date_id, :supplier_organization_id], unique: true, name: 'index_supply_date_supplier_organizations_on_ids'
    add_index :oroshi_supply_date_supplier_organizations, [:supplier_organization_id, :supply_date_id], name: 'index_supplier_organizations_supply_dates_on_ids'
  end
end
