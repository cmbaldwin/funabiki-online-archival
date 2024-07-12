class AddDivisorToMaterials < ActiveRecord::Migration[5.2]
  def change
		add_column :materials, :divisor, :decimal
  end
end
