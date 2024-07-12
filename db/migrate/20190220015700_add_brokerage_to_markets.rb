class AddBrokerageToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :brokerage, :boolean
  end
end
