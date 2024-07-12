class AddNickAndZipAndExcost2AndExcost3ToMarket < ActiveRecord::Migration[5.2]
	def change
		add_column :markets, :zip, :string
		add_column :markets, :nick, :string
		add_column :markets, :excost2, :decimal
		add_column :markets, :excost3, :decimal
	end
end
