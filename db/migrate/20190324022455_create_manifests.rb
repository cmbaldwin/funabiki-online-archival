class CreateManifests < ActiveRecord::Migration[5.2]
  def change
    create_table :manifests do |t|
      t.string :sales_date
      t.text :infomart_orders
      t.text :online_shop_orders

      t.timestamps
    end
  end
end
