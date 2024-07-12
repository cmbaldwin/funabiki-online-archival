class Oroshi::SupplyDate::SupplyTypeVariation < ApplicationRecord
  belongs_to :supply_date, class_name: 'Oroshi::SupplyDate'
  belongs_to :supply_type_variation, class_name: 'Oroshi::SupplyTypeVariation'

  validates :total, numericality: { greater_than_or_equal_to: 0 }
end
