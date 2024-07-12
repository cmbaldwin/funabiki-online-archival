class Market < ApplicationRecord
  has_many :product_and_market_joins
  has_many :products, through: :product_and_market_joins
  has_many :profit_and_market_joins
  has_many :profits, through: :profit_and_market_joins

  validates :namae,
            presence: true,
            length: { minimum: 1 }
  validates :address,
            presence: true,
            length: { minimum: 1 }
  validates :phone,
            presence: true,
            length: { minimum: 1 }
  validates :repphone,
            presence: true,
            length: { minimum: 1 }
  validates :fax,
            presence: true,
            length: { minimum: 1 }
  validates :cost,
            presence: true,
            length: { minimum: 1 }

  scope :active, -> { where(active: true) }

  def destroy
    raise "Deletion is not allowed for this model, deletions can cause errors on Profits, instead set active to false.
    このモデルの削除は許可されていません。削除はProfitsでエラーを引き起こす可能性があります。代わりに、activeをfalseに設定してください。"
  end
end
