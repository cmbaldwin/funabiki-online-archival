class CreateOroshiShippingMethod < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_shipping_methods do |t|
      t.string :name, null: false
      t.string :handle, null: false
      t.references :shipping_organization, null: false, foreign_key: { to_table: :oroshi_shipping_organizations }
      t.string :departure_times, array: true, default: []
      t.float :daily_cost, null: false, default: 0
      t.float :per_shipping_receptacle_cost, null: false, default: 0
      t.float :per_freight_unit_cost, null: false, default: 0
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
