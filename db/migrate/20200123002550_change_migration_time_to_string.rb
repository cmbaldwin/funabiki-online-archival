class ChangeMigrationTimeToString < ActiveRecord::Migration[5.2]
	def change
		change_column :frozen_oysters, :manufacture_time, :string
		add_column :frozen_oysters, :ampm, :string
	end
end
