module Oroshi
  class SupplyReceptionTime < ApplicationRecord
    has_many :supplies, class_name: 'Oroshi::Supply'
    has_and_belongs_to_many :supplier_organizations,
                            class_name: 'Oroshi::SupplierOrganization',
                            join_table: 'oroshi_supplier_organizations_oroshi_supply_reception_times'

    # attribute validations
    validates :hour, presence: true
    validates :time_qualifier, presence: true
  end
end
