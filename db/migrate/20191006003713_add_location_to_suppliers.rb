class AddLocationToSuppliers < ActiveRecord::Migration[5.2]
  def change
    add_column :suppliers, :location, :integer
  end
end
