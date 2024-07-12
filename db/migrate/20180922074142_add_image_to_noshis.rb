class AddImageToNoshis < ActiveRecord::Migration[5.2]
  def change
    add_column :noshis, :image, :string
  end
end
