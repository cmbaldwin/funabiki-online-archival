class ChangeMarketExtraCosts < ActiveRecord::Migration[5.2]
  def change
  	remove_column :markets, :excost, :decimal
    rename_column :markets, :excost2, :one_time_cost
    rename_column :markets, :excost3, :optional_cost
    add_column :markets, :one_time_cost_description, :string
    add_column :markets, :optional_cost_description, :string
  end
end
