class CreateEcProductTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :ec_product_types do |t|
      t.string :name
      t.string :counter
      t.integer :section

      t.timestamps
    end
  end
end
