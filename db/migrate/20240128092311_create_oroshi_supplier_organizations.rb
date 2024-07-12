class CreateOroshiSupplierOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supplier_organizations do |t|
      t.integer :entity_type, null: false
      t.string :entity_name, null: false
      t.string :micro_region
      t.integer :subregion_id, null: false
      t.integer :country_id, null: false
      t.string :invoice_number
      t.string :invoice_name
      t.string :honorific_title
      t.string :phone
      t.string :fax
      t.string :email
      t.boolean :active
      t.timestamps
    end
  end
end
