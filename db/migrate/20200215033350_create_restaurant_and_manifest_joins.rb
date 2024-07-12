class CreateRestaurantAndManifestJoins < ActiveRecord::Migration[5.2]
	def change
		create_table :restaurant_and_manifest_joins do |t|
			t.integer :restaurant_id
			t.integer :manifest_id
		end
	end
end
