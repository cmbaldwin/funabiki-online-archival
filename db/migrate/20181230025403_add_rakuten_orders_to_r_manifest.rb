class AddRakutenOrdersToRManifest < ActiveRecord::Migration[5.2]
  def change
    add_column :r_manifests, :Rakuten_Order, :string
  end
end
