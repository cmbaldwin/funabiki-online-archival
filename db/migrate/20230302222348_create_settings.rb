class CreateSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :settings do |t|
      t.string :name, null: false, index: { unique: true }
      t.json :settings

      t.timestamps
    end
  end
end
