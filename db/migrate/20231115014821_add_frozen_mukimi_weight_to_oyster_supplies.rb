class AddFrozenMukimiWeightToOysterSupplies < ActiveRecord::Migration[6.1]
  def change
    add_column :oyster_supplies, :frozen_mukimi_weight, :integer
  end
end
