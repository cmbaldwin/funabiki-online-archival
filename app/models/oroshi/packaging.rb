module Oroshi
  class Packaging < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Attachments
    has_one_attached :image

    # Associations
    has_and_belongs_to_many :product_variations,
                            class_name: 'Oroshi::ProductVariation',
                            join_table: 'oroshi_product_variation_packagings'
    belongs_to :product, class_name: 'Oroshi::Product', optional: true

    # Validations
    validates :name, presence: true
    validates :cost, presence: true, numericality: true

    # Scopes
    # product_id nil means that the packaging is a global packaging
    scope :global_packaging, -> { where(product_id: nil) }
  end
end
