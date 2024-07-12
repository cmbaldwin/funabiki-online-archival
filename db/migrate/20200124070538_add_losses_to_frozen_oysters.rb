class AddLossesToFrozenOysters < ActiveRecord::Migration[5.2]
  def change
    add_column :frozen_oysters, :losses, :text
  end
end
