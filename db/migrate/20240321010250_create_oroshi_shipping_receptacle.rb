class CreateOroshiShippingReceptacle < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_shipping_receptacles do |t|
      t.string :name, null: false
      t.string :handle, null: false
      t.float :cost, null: false
      t.integer :default_freight_bundle_quantity, default: 1
      t.decimal :interior_height
      t.decimal :interior_width
      t.decimal :interior_depth
      t.decimal :exterior_height
      t.decimal :exterior_width
      t.decimal :exterior_depth
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
