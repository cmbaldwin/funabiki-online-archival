class RemoveHistoryAddActiveToMarkets < ActiveRecord::Migration[6.0]
  def change
    remove_column :markets, :history
    add_column :markets, :active, :boolean, default: true
    change_column_default :markets, :brokerage, from: nil, to: true

    Market.all.each do |market|
      market.active = true
    end
  end
end
