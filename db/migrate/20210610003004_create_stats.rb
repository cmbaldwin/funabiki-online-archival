class CreateStats < ActiveRecord::Migration[6.1]
  def change
    create_table :stats do |t|
      t.date :date
      t.text :data
      t.timestamps
    end
    add_reference :frozen_oysters, :stat, index: true
    add_column :frozen_oysters, :date, :date
    add_reference :infomart_orders, :stat, index: true
    add_reference :online_orders, :stat, index: true
    add_reference :rakuten_orders, :stat, index: true
    add_reference :yahoo_orders, :stat, index: true
    add_reference :oyster_supplies, :stat, index: true
    add_column :oyster_supplies, :date, :date
    add_reference :profits, :stat, index: true
    add_column :profits, :date, :date
  end
end
