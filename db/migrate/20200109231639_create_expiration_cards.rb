class CreateExpirationCards < ActiveRecord::Migration[5.2]
  def change
    create_table :expiration_cards do |t|
      t.string :product_name
      t.string :manufacturer_address
      t.string :manufacturer
      t.string :ingredient_source
      t.string :consumption_restrictions
      t.string :manufactuered_date
      t.string :expiration_date

      t.timestamps
    end
  end
end
