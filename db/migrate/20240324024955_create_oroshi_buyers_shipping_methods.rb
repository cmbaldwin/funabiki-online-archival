class CreateOroshiBuyersShippingMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_buyers_shipping_methods do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :oroshi_buyers }
      t.references :shipping_method, null: false, foreign_key: { to_table: :oroshi_shipping_methods }
      t.timestamps
    end
  end
end
