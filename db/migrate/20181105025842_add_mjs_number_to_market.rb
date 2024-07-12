class AddMjsNumberToMarket < ActiveRecord::Migration[5.2]
	def change
		add_column :markets, :mjsnumber, :integer
	end
end
