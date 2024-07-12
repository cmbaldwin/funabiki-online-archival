class Product < ApplicationRecord
  has_many :product_and_material_joins
  has_many :materials, through: :product_and_material_joins
  has_many :product_and_market_joins
  has_many :markets, through: :product_and_market_joins
  has_many :profit_and_product_joins
  has_many :profits, through: :profit_and_product_joins

  validates :namae,
            presence: true,
            length: { minimum: 1 }
  validates :count,
            presence: true,
            length: { minimum: 1 }
  validates :multiplier,
            presence: true,
            length: { minimum: 1 }
  validates :cost,
            presence: true,
            length: { minimum: 1 }

  scope :unprofitable, -> { where(profitable: false) }
  scope :active, -> { where(active: true) }

  def destroy
    raise "Deletion is not allowed for this model, deletions can cause errors on Profits, instead set active to false.
    このモデルの削除は許可されていません。削除はProfitsでエラーを引き起こす可能性があります。代わりに、activeをfalseに設定してください。"
  end

  def types
    { 'トレイ' => '1', 'チューブ' => '2', '水切り' => '3', '殻付き' => '4', '冷凍' => '5', '単品' => '6' }
  end

  def type_check
    self.product_type = '単品' unless types.keys.include?(product_type)
  end

  def type
    type_check
    types[product_type]
  end

  def get_estimate
    estimate = 0
    materials.each do |m|
      flattened_cost = m.cost * m.divisor
      estimate += (flattened_cost * multiplier) if %w[箱 フタ 粒氷 テープ].include?(m.zairyou)
      estimate += flattened_cost if m.zairyou == 'バンド'
      next unless %w[フィルム トレイ ラベル 袋].include?(m.zairyou)

      estimate += if m.per_product
                    flattened_cost * multiplier * count
                  else
                    flattened_cost
                  end
    end
    estimate
  end
end
