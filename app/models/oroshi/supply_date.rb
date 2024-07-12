module Oroshi
  class SupplyDate < ApplicationRecord
    # Supplies
    has_many :supplies, class_name: 'Oroshi::Supply'
    # Suppliers
    has_and_belongs_to_many :suppliers,
                            class_name: 'Oroshi::Supplier',
                            join_table: 'oroshi_supply_date_suppliers'
    # Supplier Organizations
    has_and_belongs_to_many :supplier_organizations,
                            class_name: 'Oroshi::SupplierOrganization',
                            join_table: 'oroshi_supply_date_supplier_organizations'
    # Supply Types
    has_many :supply_date_supply_types, class_name: 'Oroshi::SupplyDate::SupplyType'
    has_many :supply_types, through: :supply_date_supply_types
    # Supply Type Variations
    has_many :supply_date_supply_type_variations, class_name: 'Oroshi::SupplyDate::SupplyTypeVariation'
    has_many :supply_type_variations, through: :supply_date_supply_type_variations
    # Invoices
    has_many :invoice_supply_dates, class_name: 'Oroshi::Invoice::SupplyDate'
    has_many :invoices, through: :invoice_supply_dates

    validates :date, presence: true, uniqueness: true

    scope :with_supplies, lambda {
      joins(:supplies).where.not(oroshi_supplies: { quantity: 0 }).distinct
                          }

    def supply
      supplies.where('quantity > 0')
    end

    def incomplete_supply
      supplies.where('quantity > 0 AND price = 0')
    end
  end
end
