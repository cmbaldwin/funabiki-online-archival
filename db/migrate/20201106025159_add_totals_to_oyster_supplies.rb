class AddTotalsToOysterSupplies < ActiveRecord::Migration[6.0]
  def change
    add_column :oyster_supplies, :totals, :text
  end
end
