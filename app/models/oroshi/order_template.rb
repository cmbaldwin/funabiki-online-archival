module Oroshi
  class OrderTemplate < ApplicationRecord
    # Associations
    belongs_to :order, class_name: 'Oroshi::Order', inverse_of: :order_template, dependent: :destroy
    has_one :buyer, through: :order
    has_one :product_variation, through: :order
    has_one :product, through: :product_variation
    has_one :shipping_receptacle, through: :order
    has_one :shipping_method, through: :order
    has_one :shipping_organization, through: :shipping_method

    # Validations
    validates :order, presence: true

    # Scope
    default_scope do
      includes(:order, :buyer, :product_variation, :product,
               :shipping_receptacle, :shipping_method, :shipping_organization)
    end

    def item_quantity
      order.item_quantity
    end

    def receptacle_quantity
      order.receptacle_quantity
    end

    def freight_quantity
      order.freight_quantity
    end
  end
end
