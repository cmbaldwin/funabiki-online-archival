class RenameManufactureTimeinFrozenOysters < ActiveRecord::Migration[5.2]
  def change
  	rename_column :frozen_oysters, :manufacture_time, :manufacture_date
  end
end
