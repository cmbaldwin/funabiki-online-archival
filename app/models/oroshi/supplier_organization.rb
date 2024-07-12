module Oroshi
  class SupplierOrganization < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    has_many :addresses, class_name: 'Oroshi::Address', as: :addressable
    accepts_nested_attributes_for :addresses
    has_many :suppliers, class_name: 'Oroshi::Supplier'
    has_many :supplies, through: :suppliers, class_name: 'Oroshi::Supply'
    has_and_belongs_to_many :supply_reception_times,
                            class_name: 'Oroshi::SupplyReceptionTime',
                            join_table: 'oroshi_supplier_organizations_oroshi_supply_reception_times'
    has_and_belongs_to_many :supply_dates,
                            class_name: 'Oroshi::SupplyDate',
                            join_table: 'oroshi_supply_date_supplier_organizations'

    after_update :deactivate_suppliers, if: -> { saved_change_to_active? && !active? }

    enum entity_type: { union: 0, company: 1, individual: 2, other: 3 }

    # Validations
    validates :entity_type, presence: true
    validates :entity_name, presence: true
    validates :country_id, presence: true
    validates :subregion_id, presence: true
    validates :invoice_number, presence: true
    validates :fax, presence: true

    # Scopes
    scope :by_supplier_count, lambda {
      left_joins(:suppliers)
        .group('oroshi_supplier_organizations.id')
        .order('COUNT(oroshi_suppliers.id) DESC')
    }
    scope :by_micro_region, lambda {
      order('oroshi_supplier_organizations.micro_region')
    }
    scope :by_subregion, lambda {
      order('oroshi_supplier_organizations.subregion_id')
    }

    def country
      Carmen::Country.coded(country_id.to_s.rjust(3, '0'))
    end

    def subregion
      country&.subregions&.coded(subregion_id.to_s.rjust(2, '0'))
    end

    def address
      addresses.where(default: true).first || addresses.first
    end

    private

    def deactivate_suppliers
      # Deactivate all suppliers associated with this organization, but keep them associated with the organization
      suppliers.update_all(active: false, supplier_organization_id: id)
    end
  end
end
