class CreateOroshiProduct < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_products do |t|
      t.string :name, null: false
      t.string :units, null: false
      t.decimal :exterior_height
      t.decimal :exterior_width
      t.decimal :exterior_depth
      t.references :supply_type, null: false, foreign_key: { to_table: :oroshi_supply_types }
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
