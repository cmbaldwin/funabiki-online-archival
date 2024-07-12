class CreateOroshiSuppliers < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_suppliers do |t|
      t.string :company_name
      t.string :short_name
      t.integer :supplier_number
      t.bigint :user_id
      t.text :representatives, array: true, default: []
      t.string :phone
      t.string :invoice_number
      t.string :invoice_name
      t.string :honorific_title
      t.boolean :active
      t.references :supplier_organization, null: false, foreign_key: { to_table: :oroshi_supplier_organizations }
      t.timestamps
    end
  end
end
