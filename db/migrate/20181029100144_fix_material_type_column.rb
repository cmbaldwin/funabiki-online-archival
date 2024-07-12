class FixMaterialTypeColumn < ActiveRecord::Migration[5.2]
  def change
  	rename_column :materials, :type, :zairyou
  end
end
