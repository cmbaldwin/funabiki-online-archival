class AddDownloadToExpirationCards < ActiveRecord::Migration[5.2]
  def change
    add_column :expiration_cards, :download, :string
  end
end
