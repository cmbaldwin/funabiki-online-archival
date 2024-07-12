class CreateMarkets < ActiveRecord::Migration[5.2]
  def change
    create_table :markets do |t|
      t.string :namae
      t.string :address
      t.string :phone
      t.string :repphone
      t.string :fax
      t.decimal :cost
      t.decimal :excost
      t.string :history

      t.timestamps
    end
  end
end
