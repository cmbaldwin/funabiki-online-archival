class ProfitAndMarketJoin < ApplicationRecord
  belongs_to :profit, touch: true
  belongs_to :market, touch: true
end
