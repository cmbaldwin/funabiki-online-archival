class ProductAndMarketJoin < ApplicationRecord
  belongs_to :product, touch: true
  belongs_to :market, touch: true
end
