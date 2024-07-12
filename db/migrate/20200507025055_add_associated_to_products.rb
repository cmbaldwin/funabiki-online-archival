class AddAssociatedToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :associated, :boolean, default: false
  end
end
