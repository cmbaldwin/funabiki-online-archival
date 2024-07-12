class AddRestaurantSectionsToEcProductTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :ec_product_types, :restaurant_raw_section, :integer
    add_column :ec_product_types, :restaurant_frozen_section, :integer
  end
end
