class CreateProductAndMaterialJoin < ActiveRecord::Migration[5.2]
	def change
		create_table :product_and_material_joins do |t|
			t.integer :product_id
			t.integer :material_id
		end
	end
end
