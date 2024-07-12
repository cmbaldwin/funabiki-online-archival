class AddNotesToProfits < ActiveRecord::Migration[5.2]
	def change
		add_column :profits, :notes, :text
	end
end
