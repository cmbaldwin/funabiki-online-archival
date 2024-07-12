class AddInfoMartAssociationToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :infomart_association, :text
  end
end
