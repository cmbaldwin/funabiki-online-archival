class AddNamae2ToNoshis < ActiveRecord::Migration[5.2]
  def change
    add_column :noshis, :namae2, :string
    add_column :noshis, :namae3, :string
    add_column :noshis, :namae4, :string
    add_column :noshis, :namae5, :string
  end
end
