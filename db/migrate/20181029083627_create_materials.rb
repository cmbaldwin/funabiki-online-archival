class CreateMaterials < ActiveRecord::Migration[5.2]
  def change
    create_table :materials do |t|
      t.string :name
      t.string :type
      t.decimal :cost
      t.string :history

      t.timestamps
    end
  end
end
