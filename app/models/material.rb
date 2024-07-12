class Material < ApplicationRecord
  has_many :product_and_material_joins
  has_many :products, through: :product_and_material_joins
  serialize :history

  validates :namae,
            presence: true,
            length: { minimum: 1 }
  validates :zairyou,
            presence: true,
            length: { minimum: 1 }
  validates :cost,
            presence: true,
            length: { minimum: 1 }
end
