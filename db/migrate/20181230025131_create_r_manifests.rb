class CreateRManifests < ActiveRecord::Migration[5.2]
  def change
    create_table :r_manifests do |t|
      t.text :orders_hash

      t.timestamps
    end
  end
end
