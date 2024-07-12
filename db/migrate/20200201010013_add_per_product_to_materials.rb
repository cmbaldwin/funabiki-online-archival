class AddPerProductToMaterials < ActiveRecord::Migration[5.2]
  def change
    add_column :materials, :per_product, :boolean
  end
end
