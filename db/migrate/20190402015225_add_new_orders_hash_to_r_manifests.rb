class AddNewOrdersHashToRManifests < ActiveRecord::Migration[5.2]
  def change
    add_column :r_manifests, :new_orders_hash, :text
  end
end
