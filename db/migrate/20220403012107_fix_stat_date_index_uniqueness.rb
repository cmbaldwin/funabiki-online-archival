class FixStatDateIndexUniqueness < ActiveRecord::Migration[6.1]
  def change
    remove_index :stats, :date
    add_index :stats, :date, unique: true
  end
end
