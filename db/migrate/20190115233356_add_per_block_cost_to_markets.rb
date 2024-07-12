class AddPerBlockCostToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :block_cost, :decimal
  end
end