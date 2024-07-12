class AddOystersLastUpdateToOysterSupplies < ActiveRecord::Migration[6.0]
  def change
    add_column :oyster_supplies, :oysters_last_update, :datetime
  end
end
