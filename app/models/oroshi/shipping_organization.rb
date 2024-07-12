module Oroshi
  class ShippingOrganization < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    has_many :addresses, as: :addressable, class_name: 'Oroshi::Address'
    has_many :shipping_methods, class_name: 'Oroshi::ShippingMethod'
    has_many :buyers, through: :shipping_methods
    has_many :orders, through: :buyers

    # Validations
    validates :name, :handle, presence: true
    validates :handle, uniqueness: true
  end
end
