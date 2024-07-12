class ChangeProductHistoryToText < ActiveRecord::Migration[5.2]
	def up
		change_column :products, :history, :text
	end
	def down
		# This might cause trouble if you have strings longer
		# than 255 characters.
		change_column :products, :history, :string
	end
end
