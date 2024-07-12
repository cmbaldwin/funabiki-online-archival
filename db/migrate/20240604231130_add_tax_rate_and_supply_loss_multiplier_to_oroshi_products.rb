class AddTaxRateAndSupplyLossMultiplierToOroshiProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :oroshi_products, :tax_rate, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :oroshi_products, :supply_loss_adjustment, :decimal, precision: 5, scale: 2, default: 1.0
  end
end
