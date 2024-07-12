class CreateOroshiSupplyTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_types do |t|
      t.string :name
      t.string :handle
      t.string :units
      t.boolean :active
      t.boolean :liquid, default: false
      t.timestamps
    end
  end
end
