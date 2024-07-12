class CreateOroshiShippingOrganization < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_shipping_organizations do |t|
      t.string :name, null: false
      t.string :handle, null: false
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
