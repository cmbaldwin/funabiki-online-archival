class AddFurusatoOrdersReferenceToStats < ActiveRecord::Migration[6.1]
  def change
    add_reference :furusato_orders, :stat, index: true
  end
end
