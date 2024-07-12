class CreateOroshiInvoiceSupplierOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_invoice_supplier_organizations do |t|
      t.references :invoice, null: false, foreign_key: { to_table: :oroshi_invoices, on_delete: :cascade }
      t.references :supplier_organization, null: false, foreign_key: { to_table: :oroshi_supplier_organizations }
      t.jsonb :passwords, default: {}
      t.boolean :completed, default: false
      t.datetime :sent_at
      t.timestamps
    end
  end
end
