class AddSubtotalsToProfit < ActiveRecord::Migration[5.2]
  def change
    add_column :profits, :subtotals, :text
  end
end
