class AddNoshiUrlToNoshis < ActiveRecord::Migration[5.2]
  def change
  	add_column :noshis, :noshi_url, :string
  end
end
