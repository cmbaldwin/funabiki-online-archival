module Oroshi
  class ProductionZone < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Associations
    has_and_belongs_to_many :product_variations,
                            class_name: 'Oroshi::ProductVariation',
                            join_table: 'oroshi_product_variation_production_zones'

    # Validations
    validates :name, presence: true
  end
end
