class AddLastActivityAtToProductAndMarketJoins < ActiveRecord::Migration[7.1]
  def change
    add_column :product_and_market_joins, :last_activity_at, :datetime
  end
end
