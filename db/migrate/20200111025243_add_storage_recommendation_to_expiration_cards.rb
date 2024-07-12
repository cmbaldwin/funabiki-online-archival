class AddStorageRecommendationToExpirationCards < ActiveRecord::Migration[5.2]
  def change
    add_column :expiration_cards, :storage_recommendation, :string
  end
end
