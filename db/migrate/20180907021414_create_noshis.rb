class CreateNoshis < ActiveRecord::Migration[5.2]
  def change
    create_table :noshis do |t|
      t.integer :ntype
      t.string :omotegaki
      t.string :namae

      t.timestamps
    end
  end
end
