class CreateOroshiSupplyDates < ActiveRecord::Migration[7.1]
  def change
    create_table :oroshi_supply_dates do |t|
      t.date :date, null: false
      t.jsonb :totals, default: {}
      t.timestamps
    end
    add_index :oroshi_supply_dates, :date, unique: true
  end
end
