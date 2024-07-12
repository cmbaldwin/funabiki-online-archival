class CreateOysterInvoices < ActiveRecord::Migration[6.0]
  def change
    create_table :oyster_invoices do |t|
      t.string :start_date
      t.string :end_date
      t.string :aioi_all_pdf
      t.string :aioi_seperated_pdf
      t.string :sakoshi_all_pdf
      t.string :sakoshi_seperated_pdf
      t.boolean :completed
      t.string :aioi_emails
      t.string :sakoshi_emails
      t.datetime :send_at, precision: 0
      t.text :data

      t.timestamps
    end
  end
end
