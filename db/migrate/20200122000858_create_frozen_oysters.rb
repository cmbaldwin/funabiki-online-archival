class CreateFrozenOysters < ActiveRecord::Migration[5.2]
  def change
    create_table :frozen_oysters do |t|
      t.decimal :hyogo_raw
      t.decimal :sakoshi_raw
      t.text :frozen_l
      t.text :frozen_ll
      t.text :finished_packs

      t.timestamps
    end
  end
end
