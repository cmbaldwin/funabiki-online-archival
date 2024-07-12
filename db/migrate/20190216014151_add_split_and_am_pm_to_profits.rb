class AddSplitAndAmPmToProfits < ActiveRecord::Migration[5.2]
  def change
    add_column :profits, :split, :boolean
    add_column :profits, :ampm, :boolean
  end
end
