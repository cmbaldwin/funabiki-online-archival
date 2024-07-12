class RemoveHistoryAndInfomartAssociationFromProducts < ActiveRecord::Migration[7.1]
  def change
    remove_column :products, :history, :text
    remove_column :products, :infomart_association, :text
  end
end
