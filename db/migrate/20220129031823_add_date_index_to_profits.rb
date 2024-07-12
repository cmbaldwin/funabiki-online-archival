class AddDateIndexToProfits < ActiveRecord::Migration[6.1]
  def change
    add_index :profits, :date
  end
end
