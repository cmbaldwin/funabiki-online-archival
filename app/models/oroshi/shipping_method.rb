module Oroshi
  class ShippingMethod < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    belongs_to :shipping_organization, class_name: 'Oroshi::ShippingOrganization'
    has_many :orders, class_name: 'Oroshi::Order'
    has_and_belongs_to_many :buyers,
                            class_name: 'Oroshi::Buyer',
                            join_table: 'oroshi_buyers_shipping_methods'

    # Attribute validations
    validates :name, :handle, presence: true, uniqueness: true
    validates :shipping_organization, presence: true
    validates :daily_cost, :per_shipping_receptacle_cost, :per_freight_unit_cost,
              presence: true, numericality: { greater_than_or_equal_to: 0 }
  end
end
