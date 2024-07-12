class AddFunabikiOrderReferenceToStats < ActiveRecord::Migration[6.1]
  def change
    add_reference :funabiki_orders, :stat, index: true
  end
end
