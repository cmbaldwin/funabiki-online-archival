class CreateOysterSupplies < ActiveRecord::Migration[5.2]
  def change
    create_table :oyster_supplies do |t|
      t.text :oysters
      t.date :supply_date

      t.timestamps
    end
  end
end
