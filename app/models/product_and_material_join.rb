class ProductAndMaterialJoin < ApplicationRecord
  belongs_to :product, touch: true
  belongs_to :material, touch: true
end
