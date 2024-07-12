class CreateOroshiInvoiceSupplyDates < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_invoice_supply_dates do |t|
      t.references :invoice, null: false, foreign_key: { to_table: :oroshi_invoices, on_delete: :cascade }
      t.references :supply_date, null: false, foreign_key: { to_table: :oroshi_supply_dates }
      t.timestamps
    end
  end
end
