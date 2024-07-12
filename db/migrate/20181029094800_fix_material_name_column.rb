class FixMaterialNameColumn < ActiveRecord::Migration[5.2]
  def change
  	rename_column :materials, :name, :namae
  end
end
