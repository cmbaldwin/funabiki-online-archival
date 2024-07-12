class AddVariousDateIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :yahoo_orders, :ship_date
    add_index :rakuten_orders, :ship_dates
    add_index :oyster_supplies, :date
    add_index :online_orders, :ship_date
    add_index :infomart_orders, :ship_date
    add_index :furusato_noze_dates, :date
    add_index :furusato_orders, :shipped_date
    add_index :frozen_oysters, :date
    add_index :markets, :mjsnumber
    add_index :markets, :id
    add_index :products, :namae
    add_index :profits, :id
    add_index :stats, :date
    add_index :noshis, :id
  end
end
