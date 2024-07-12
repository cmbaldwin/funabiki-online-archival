class AddManufactureDateToFrozenOysters < ActiveRecord::Migration[5.2]
  def change
    add_column :frozen_oysters, :manufacture_time, :datetime
  end
end
