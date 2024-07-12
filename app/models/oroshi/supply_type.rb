module Oroshi
  class SupplyType < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable
    after_update :deactivate_supply_type_variations, if: -> { saved_change_to_active? && !active? }

    # Assocations
    has_many :supply_type_variations, class_name: 'Oroshi::SupplyTypeVariation'
    has_many :supply_date_supply_types, class_name: 'Oroshi::SupplyDate::SupplyType'
    has_many :supply_dates, through: :supply_date_supply_types
    has_many :supplies, through: :supply_dates, class_name: 'Oroshi::Supply'

    # Validations
    validates :name, presence: true
    validates :units, presence: true
    validates :handle, presence: true
    validates :liquid, inclusion: { in: [true, false] }

    def to_s
      name + ' (' + units + ')'
    end

    def to_var
      "type_#{id}"
    end

    private

    def deactivate_supply_type_variations
      supply_type_variations.update_all(active: false, supply_type_id: id)
    end
  end
end
