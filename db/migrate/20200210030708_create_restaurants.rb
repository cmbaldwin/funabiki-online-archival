class CreateRestaurants < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurants do |t|
      t.string :namae
      t.string :company
      t.string :link
      t.string :address
      t.string :arrival_time
      t.text :products
      t.text :stats

      t.timestamps
    end
  end
end
