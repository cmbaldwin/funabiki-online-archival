class AddPhoneToSuppliers < ActiveRecord::Migration[5.2]
  def change
    add_column :suppliers, :phone, :integer
  end
end
