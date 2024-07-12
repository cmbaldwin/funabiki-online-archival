class CreateProfits < ActiveRecord::Migration[5.2]
  def change
    create_table :profits do |t|
      t.string :date
      t.text :figures
      t.text :totals

      t.timestamps
    end
  end
end
