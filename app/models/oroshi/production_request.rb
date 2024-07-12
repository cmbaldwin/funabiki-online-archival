module Oroshi
  class ProductionRequest < ApplicationRecord
    # Associations
    belongs_to :product_variation, class_name: 'Oroshi::ProductVariation'
    has_many :supply_type_variations, through: :product_variation
    belongs_to :product_inventory, class_name: 'Oroshi::ProductInventory'
    accepts_nested_attributes_for :product_inventory
    belongs_to :production_zone, class_name: 'Oroshi::ProductionZone'
    belongs_to :shipping_receptacle, class_name: 'Oroshi::ShippingReceptacle', optional: true

    # Validations
    validates :status, presence: true
    validates :request_quantity, :fulfilled_quantity, presence: true, numericality: { only_integer: true }
    validates :product_inventory, :product_variation, :production_zone, :shipping_receptacle, presence: true

    # Callbacks
    before_validation :derive_attributes_from_product_inventory, on: %i[create]

    # Enums
    enum status: { pending: 0, in_progress: 1, completed: 2 }

    attr_accessor :previous_fulfilled_quantity

    # Callbacks
    before_update :store_previous_fulfilled_quantity
    after_update :update_product_inventory

    def quantity
      fulfilled_quantity - request_quantity
    end

    private

    def derive_attributes_from_product_inventory
      return unless product_inventory

      self.product_variation ||= product_inventory.product_variation
      self.production_zone ||= product_inventory.product_variation.production_zones.first
      self.shipping_receptacle ||= product_inventory.product_variation.default_shipping_receptacle
    end

    def store_previous_fulfilled_quantity
      self.previous_fulfilled_quantity = fulfilled_quantity_was
    end

    def update_product_inventory
      difference = fulfilled_quantity - previous_fulfilled_quantity
      product_inventory.quantity += difference
      product_inventory.save!
    end
  end
end
