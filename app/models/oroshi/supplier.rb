module Oroshi
  class Supplier < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    has_many :addresses, class_name: 'Oroshi::Address', as: :addressable
    accepts_nested_attributes_for :addresses
    has_many :supplies, class_name: 'Oroshi::Supply'
    belongs_to :supplier_organization, class_name: 'Oroshi::SupplierOrganization'
    has_and_belongs_to_many :supply_type_variations,
                            class_name: 'Oroshi::SupplyTypeVariation',
                            join_table: 'oroshi_suppliers_oroshi_supply_type_variations'
    has_and_belongs_to_many :supply_dates,
                            class_name: 'Oroshi::SupplyDate',
                            join_table: 'oroshi_supply_date_suppliers'
    has_many :supply_reception_times, through: :supplier_organization, class_name: 'Oroshi::SupplyReceptionTime'

    # Validations
    validates :company_name, presence: true
    validates :supplier_number, presence: true
    validates :representatives, presence: true
    validates :invoice_number, presence: true
    validates :supplier_organization_id, presence: true

    def circled_number
      int = supplier_number.to_i
      return unless int.positive? && int < 20

      (9312..9331).map { |i| i.chr(Encoding::UTF_8) }[int - 1]
    end
  end
end
