class CreateOroshiMaterialCategory < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_material_categories do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
