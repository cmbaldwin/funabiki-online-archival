class AddShomiorhiToExpirationCards < ActiveRecord::Migration[5.2]
  def change
    add_column :expiration_cards, :shomiorhi, :boolean
  end
end
