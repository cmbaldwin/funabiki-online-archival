class AddOroshiProductToOroshiPackaging < ActiveRecord::Migration[7.1]
  def change
    add_reference :oroshi_packagings, :product, foreign_key: { to_table: :oroshi_products }
  end
end
