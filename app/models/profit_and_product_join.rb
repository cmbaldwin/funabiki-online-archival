class ProfitAndProductJoin < ApplicationRecord
  belongs_to :profit, touch: true
  belongs_to :product, touch: true
end
