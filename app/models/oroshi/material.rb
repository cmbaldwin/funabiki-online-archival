module Oroshi
  class Material < ApplicationRecord
    # Callbacks
    include Oroshi::Activatable

    # Attachments
    has_one_attached :image

    # Associations
    has_and_belongs_to_many :products,
                            class_name: 'Oroshi::Product',
                            join_table: 'oroshi_product_materials'
    belongs_to :material_category

    # Validations
    validates :name, :per, presence: true
    validates :cost, presence: true, numericality: true

    # Enum
    enum per: { item: 0, shipping_receptacle: 1, freight: 2, supply_type_unit: 3 }
  end
end
