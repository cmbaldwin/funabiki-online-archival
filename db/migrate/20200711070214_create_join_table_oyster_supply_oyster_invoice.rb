class CreateJoinTableOysterSupplyOysterInvoice < ActiveRecord::Migration[6.0]
  def change
    create_join_table :oyster_supplies, :oyster_invoices do |t|
      #t.index [:oyster_supply_id, :oyster_invoice_id]
      t.index [:oyster_invoice_id, :oyster_supply_id], name: :supply_invoice_index
    end
  end
end
