class CreateOroshiPackaging < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_packagings do |t|
      t.string :name, null: false
      t.float :cost, null: false
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
