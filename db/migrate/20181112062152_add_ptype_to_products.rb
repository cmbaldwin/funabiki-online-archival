class AddPtypeToProducts < ActiveRecord::Migration[5.2]
	def change
		add_column :products, :ptype, :string
	end
end
