class AddRepsAndHomeAddressToSuppliers < ActiveRecord::Migration[5.2]
  def change
    add_column :suppliers, :representatives, :text, array: true, default: []
    add_column :suppliers, :home_address, :string
    remove_column :suppliers, :representative_name
  end
end
