class CreateProfitAndProductJoins < ActiveRecord::Migration[5.2]
  def change
    create_table :profit_and_product_joins do |t|
			t.integer :profit_id
			t.integer :product_id
    end
  end
end
