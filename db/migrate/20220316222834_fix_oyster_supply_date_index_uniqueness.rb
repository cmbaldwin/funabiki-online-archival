class FixOysterSupplyDateIndexUniqueness < ActiveRecord::Migration[6.1]
  def change
    remove_index :oyster_supplies, :date
    add_index :oyster_supplies, :date, unique: true
  end
end
