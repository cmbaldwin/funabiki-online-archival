class CreateEcProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :ec_products do |t|
      t.string :name, null: false
      t.references :ec_product_type, null: false, index: true
      t.string :cross_reference_ids, null: false, array: true, default: []
      t.integer :quantity

      t.timestamps
    end
  end
end
