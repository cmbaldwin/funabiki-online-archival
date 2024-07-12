class DropRManifests < ActiveRecord::Migration[7.1]
  def change
    drop_table :r_manifests
  end
end
