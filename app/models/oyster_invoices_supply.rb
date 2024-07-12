class OysterInvoicesSupply < ApplicationRecord
  belongs_to :oyster_supply, touch: true
  belongs_to :oyster_invoice, touch: true
end
