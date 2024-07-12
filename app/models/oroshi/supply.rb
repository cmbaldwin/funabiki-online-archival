module Oroshi
  class Supply < ApplicationRecord
    # Callbacks
    include Turbo::Streams::ActionHelper
    after_commit :update_join_records, if: -> { saved_change_to_quantity? }

    # Associations
    belongs_to :supply_date, class_name: 'Oroshi::SupplyDate', foreign_key: 'supply_date_id', touch: true
    belongs_to :supplier, class_name: 'Oroshi::Supplier'
    has_one :supplier_organization, through: :supplier, class_name: 'Oroshi::SupplierOrganization'
    belongs_to :supply_type_variation, class_name: 'Oroshi::SupplyTypeVariation'
    has_one :supply_type, through: :supply_type_variation, class_name: 'Oroshi::SupplyType'
    belongs_to :supply_reception_time, class_name: 'Oroshi::SupplyReceptionTime'

    # Validations
    validates :supply_date_id, presence: true
    validates :supplier_id, presence: true
    validates :supply_type_variation_id, presence: true
    validates :supply_reception_time_id, presence: true
    validates :quantity, :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

    broadcasts :supply, inserts_by: :replace, on: %i[update]

    # Scopes
    scope :with_quantity, -> { where('quantity > 0') }
    scope :incomplete, -> { where('quantity > 0 AND price = 0') }
    scope :complete, -> { where('quantity > 0 AND price > 0') }

    def incomplete?
      quantity.positive? && price.zero?
    end

    private

    def update_join_records
      @sibling_supplies = supply_date.supplies.includes(:supply_type_variation)
      supply_type_join
      supply_type_variation_join

      supply_date.suppliers << supplier unless supply_date.suppliers.exists?(supplier.id)
      return if supply_date.supplier_organizations.exists?(supplier.supplier_organization.id)

      supply_date.supplier_organizations << supplier.supplier_organization
    end

    def supply_type_join
      Oroshi::SupplyDate::SupplyType.find_or_create_by(
        supply_date: supply_date,
        supply_type: supply_type_variation.supply_type
      ).update(total: @sibling_supplies.select do |supply|
          supply.supply_type_variation.supply_type == supply_type_variation.supply_type
                      end.sum(&:quantity))
    end

    def supply_type_variation_join
      Oroshi::SupplyDate::SupplyTypeVariation.find_or_create_by(
        supply_date: supply_date,
        supply_type_variation: supply_type_variation
      ).update(total: @sibling_supplies.select do |supply|
          supply.supply_type_variation == supply_type_variation
                      end.sum(&:quantity))
    end
  end
end
