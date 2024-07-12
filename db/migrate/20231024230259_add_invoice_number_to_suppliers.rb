class AddInvoiceNumberToSuppliers < ActiveRecord::Migration[6.1]
  def change
    add_column :suppliers, :invoice_number, :string
  end
end
