class ChangeDateToStringInOysterSupplies < ActiveRecord::Migration[5.2]
  def change
    remove_column :oyster_supplies, :supply_date, :date
    add_column :oyster_supplies, :supply_date, :string
  end
end
