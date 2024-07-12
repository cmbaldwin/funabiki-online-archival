class RenameFrozenInEcProducts < ActiveRecord::Migration[7.1]
  def change
    rename_column :ec_products, :frozen, :frozen_item
  end
end
