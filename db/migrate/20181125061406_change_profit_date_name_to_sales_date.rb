class ChangeProfitDateNameToSalesDate < ActiveRecord::Migration[5.2]
  def change
    rename_column :profits, :date, :sales_date
  end
end
