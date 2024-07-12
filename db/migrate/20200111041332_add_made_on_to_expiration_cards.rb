class AddMadeOnToExpirationCards < ActiveRecord::Migration[5.2]
  def change
    add_column :expiration_cards, :made_on, :boolean
  end
end
