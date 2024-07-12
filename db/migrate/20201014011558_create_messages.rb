class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.integer :user
      t.string :model
      t.string :message
      t.boolean :state
      t.text :data

      t.timestamps
    end
  end
end
