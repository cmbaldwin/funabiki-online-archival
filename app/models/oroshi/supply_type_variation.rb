module Oroshi
  class SupplyTypeVariation < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    belongs_to :supply_type, class_name: 'Oroshi::SupplyType'
    has_and_belongs_to_many :suppliers,
                            class_name: 'Oroshi::Supplier',
                            join_table: 'oroshi_suppliers_oroshi_supply_type_variations'
    has_and_belongs_to_many :product_variations,
                            class_name: 'Oroshi::ProductVariation',
                            join_table: 'oroshi_product_variation_supply_type_variations'
    has_many :supplies, class_name: 'Oroshi::Supply'
    has_many :supply_date_supply_type_variations, class_name: 'Oroshi::SupplyDate::SupplyTypeVariation'
    has_many :supply_dates, through: :supply_date_supply_type_variations
    has_many :supplies, through: :supply_dates, class_name: 'Oroshi::Supply'

    # Validations
    validates :supply_type_id, presence: true
    validates :name, presence: true
    validates :default_container_count, presence: true

    def to_s
      "#{supply_type.name} (#{name})"
    end

    def to_var
      "variation_#{id}"
    end

    def units
      supply_type.units
    end
  end
end
