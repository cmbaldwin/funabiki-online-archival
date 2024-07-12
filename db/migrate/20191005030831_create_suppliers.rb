class CreateSuppliers < ActiveRecord::Migration[5.2]
  def change
    create_table :suppliers do |t|
      t.string :company_name
      t.integer :supplier_number
      t.string :address
      t.string :representative_name
      t.belongs_to :user

      t.timestamps
    end
  end
end
