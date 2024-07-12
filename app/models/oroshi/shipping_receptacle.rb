module Oroshi
  class ShippingReceptacle < ApplicationRecord
    include Oroshi::Activatable

    # Attachments
    has_one_attached :image

    # Associations
    has_many :production_requests, class_name: 'Oroshi::ProductionRequest'
    has_many :orders, class_name: 'Oroshi::Order'

    # Validations
    validates :name, presence: true
    validates :handle, presence: true
    validates :cost, presence: true, numericality: true
    validates :default_freight_bundle_quantity, numericality: { greater_than: 0 }
    validates_numericality_of :interior_height, :interior_width, :interior_depth,
                              :exterior_height, :exterior_width, :exterior_depth,
                              greater_than_or_equal_to: 0

    def estimate_per_box_quantity(product, adjustment: 0.90)
      # Calculate the volume of the shipping receptacle and the product
      # subtract a bit for packing space (e.g. ice or padding) -- 10% of the volume
      receptacle_volume = interior_height * interior_width * interior_depth * adjustment
      product_volume = product.exterior_height * product.exterior_width * product.exterior_depth

      # Calculate and return the number of products that can fit in the shipping receptacle
      # round down to nearest multiple of 5
      estimate = (receptacle_volume / product_volume).floor.div(5) * 5
      estimate.zero? ? 1 : estimate
    end
  end
end
