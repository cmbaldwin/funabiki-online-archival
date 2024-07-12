class AddVolumesToProfits < ActiveRecord::Migration[6.0]
  def change
    add_column :profits, :volumes, :text
  end
end
