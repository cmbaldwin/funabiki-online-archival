class CreateOroshiInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_invoices do |t|
      t.date :start_date
      t.date :end_date
      t.boolean :send_email
      t.datetime :send_at
      t.datetime :sent_at
      t.integer :invoice_layout

      t.timestamps
    end
  end
end
