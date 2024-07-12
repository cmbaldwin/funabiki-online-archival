class CreateOroshiSupplyTypeVariations < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_type_variations do |t|
      t.string :name
      t.string :handle
      t.integer :default_container_count
      t.boolean :active
      t.references :supply_type, null: false, foreign_key: { to_table: :oroshi_supply_types }
      t.timestamps
    end
  end
end
