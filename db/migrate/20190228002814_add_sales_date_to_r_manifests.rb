class AddSalesDateToRManifests < ActiveRecord::Migration[5.2]
  def change
    add_column :r_manifests, :sales_date, :string
  end
end
