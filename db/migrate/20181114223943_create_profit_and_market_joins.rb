class CreateProfitAndMarketJoins < ActiveRecord::Migration[5.2]
  def change
    create_table :profit_and_market_joins do |t|
			t.integer :profit_id
			t.integer :market_id
    end
  end
end
