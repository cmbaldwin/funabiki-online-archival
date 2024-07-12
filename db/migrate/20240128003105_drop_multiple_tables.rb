class DropMultipleTables < ActiveRecord::Migration[7.1]
  def up
    drop_table :restaurants
    drop_table :restaurant_and_manifest_joins
    drop_table :manifests
    drop_table :furusato_noze_dates
    drop_table :frozen_oysters
    drop_table :comments
    drop_table :categories
    drop_table :articles
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
