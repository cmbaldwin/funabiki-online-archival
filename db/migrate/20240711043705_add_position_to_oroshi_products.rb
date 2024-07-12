class AddPositionToOroshiProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_products, :position, :integer

    # Reset column information to make the new column available to model
    Oroshi::Product.reset_column_information

    # Iterate through each product, ordered by created_at, and assign positions
    Oroshi::Product.order(:created_at).each_with_index do |product, index|
      product.update(position: index)
    end
  end
end
