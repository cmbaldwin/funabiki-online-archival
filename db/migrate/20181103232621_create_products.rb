class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :namae
      t.decimal :grams
      t.decimal :excost
      t.decimal :count
      t.decimal :multipl
      t.string :history

      t.timestamps
    end
  end
end
