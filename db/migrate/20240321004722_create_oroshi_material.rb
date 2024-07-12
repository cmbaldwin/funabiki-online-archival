class CreateOroshiMaterial < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_materials do |t|
      t.string :name, null: false
      t.float :cost, null: false
      t.integer :per, null: false
      t.boolean :active, default: true
      t.references :material_category, null: false, foreign_key: { to_table: :oroshi_material_categories }
      t.timestamps
    end
  end
end
