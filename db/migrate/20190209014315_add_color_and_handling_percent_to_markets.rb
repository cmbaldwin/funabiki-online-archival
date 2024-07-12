class AddColorAndHandlingPercentToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :color, :string
    add_column :markets, :handling, :decimal
  end
end
