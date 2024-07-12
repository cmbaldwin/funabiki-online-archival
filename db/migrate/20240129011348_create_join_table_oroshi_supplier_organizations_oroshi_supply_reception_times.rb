class CreateJoinTableOroshiSupplierOrganizationsOroshiSupplyReceptionTimes < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supplier_organizations_oroshi_supply_reception_times do |t|
      t.references :supplier_organization, null: false, foreign_key: { to_table: :oroshi_supplier_organizations }
      t.references :supply_reception_time, null: false, foreign_key: { to_table: :oroshi_supply_reception_times }
    end
  end
end
