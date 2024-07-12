class CreateOroshiSupplyReceptionTimes < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_reception_times do |t|
      t.integer :hour
      t.string :time_qualifier
      t.timestamps
    end
  end
end
