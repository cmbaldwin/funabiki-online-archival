class CreateProductAndMarketJoin < ActiveRecord::Migration[5.2]
	def change
		create_table :product_and_market_joins do |t|
			t.integer :product_id
			t.integer :market_id
		end
	end
end
