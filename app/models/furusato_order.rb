class FurusatoOrder < ApplicationRecord
  belongs_to :stat, optional: true
  before_save :set_est_shipping_date

  scope :unfinished, -> { where.not(order_status: '締処理済') }
  scope :has_memo, -> { where(order_status: %w[出荷準備中 出荷依頼]).where.not(sale_memo: '') }
  scope :accepted, -> { where(order_status: '出荷準備中') }
  scope :request, -> { where(order_status: '出荷依頼') }
  scope :undated, -> { where(est_shipping_date: nil) }
  scope :dated, -> { where.not(est_shipping_date: nil) }
  scope :with_date, ->(date) { where(shipped_date: [date]) }
  scope :with_dates, ->(date_range) { where(shipped_date: date_range) }
  # Searches by order time (may exclude some orders on the season edge)
  scope :this_season, -> { where(est_shipping_date: FurusatoOrder.last.this_season_start..FurusatoOrder.last.this_season_end) }
  scope :prior_season, -> { where(est_shipping_date: FurusatoOrder.last.prior_season_start..FurusatoOrder.last.prior_season_end) }

  # Schema Reference
  #   t.integer 'ssys_id'
  #   t.string 'furusato_id'
  #   t.string 'katakana_name'
  #   t.string 'kanji_name'
  #   t.string 'title'
  #   t.string 'product_code'
  #   t.string 'product_name'
  #   t.string 'order_status'
  #   t.date 'system_entry_date'
  #   t.date 'shipped_date'
  #   t.date 'est_arrival_date'
  #   t.date 'est_shipping_date'
  #   t.string 'arrival_time'
  #   t.string 'shipping_company'
  #   t.string 'shipping_number'
  #   t.string 'details_url'
  #   t.string 'address'
  #   t.string 'phone'
  #   t.string 'sale_memo'
  #   t.string 'mail_memo'
  #   t.string 'lead_time'
  #   t.string 'noshi'
  #   t.datetime 'created_at', precision: 6, null: false
  #   t.datetime 'updated_at', precision: 6, null: false

  def set_est_shipping_date
    self.est_shipping_date = shipping_date
  end

  def date
    shipped_date || est_shipping_date
  end

  def shipping_date
    date || system_entry_date
  end

  def total_price
    estimate_sales_total
  end

  def profit_estimate
    (total_price - expenses_estimate - raw_costs).to_i
  end

  def order_time
    shipping_date.to_time
  end

  def code
    product_code.to_i
  end

  def shell_count
    count[1]
  end

  def bara_count
    count[9]
  end

  def mukimi_count
    count[0]
  end

  def triploid_count
    0
  end

  def mukimi_sales_estimate
    return 0 unless mukimi_count.positive?

    # Just estimate a blanket price for shell profit
    total_price - (count[1] * 100)
  end

  def mukimi_per_pack_sales
    return 0 unless mukimi_count.positive?

    mukimi_sales_estimate / mukimi_count
  end

  def mukimi_profit_estimate
    return 0 unless mukimi_count.positive?

    (mukimi_sales_estimate - (raw_oyster_costs(shipping_date).values[0] + (60 * mukimi_count))).to_i - expenses_estimate
  end

  def pack_profit_estimate
    return 0 unless mukimi_count.positive?

    mukimi_profit_estimate / mukimi_count
  end

  def estimate_sales_total
    est_sales_hash = {
      85701774 => 4100, # rm2
      85701775 => 4100, # rk27
      85701776 => 4100, # rs112
      85701777 => 4100, # rs112
      85701778 => 7600, # rs226
      85701780 => 7600, # rs226
      85704329 => 4100, # a300j
      85704330 => 4100, # a300g
      85704328 => 4100, # tk1
      85709405 => 4100, # em1003
      85709404 => 4100, # ek1005
      85701779 => 7600, # rk86
      85664213 => 4100,  # m2
      85664214 => 4100,  # k28
      85664217 => 7600,  # k60
      85664220 => 10600, # k90
      85664215 => 4100,  # s112
      85664216 => 7600,  # s226
      85664221 => 10600  # s342
    }
    est_sales_hash.include?(code) ? est_sales_hash[code] : 4100
  end

  def expenses_estimate
    # Box, Knife (if there), tape, ice, color paper insert
    est_sales_hash = {
      85701774 => 250, # rm2
      85701775 => 200, # rk27
      85701776 => 270, # rs112
      85701777 => 270, # rs112
      85701778 => 360, # rs226
      85701780 => 360, # rs226
      85704329 => 420, # a300j
      85704330 => 420, # a300g
      85704328 => 220, # tk1
      85709405 => 400, # em1003
      85709404 => 400, # ek1005
      85701779 => 265, # rk86
      85664213 => 350,  # m2
      85664214 => 400,  # k28
      85664217 => 450,  # k60
      85664220 => 450,  # k90
      85664215 => 430,  # s112
      85664216 => 490,  # s226
      85664221 => 550   # s342
    }
    est_sales_hash.include?(code) ? est_sales_hash[code] : 300
  end

  def raw_costs
    costs = raw_oyster_costs(shipping_date).values
    est_sales_hash = {
      85701774 => 1000, # rm2
      85701775 => 1350, # rk27
      85701776 => 1100, # rs112
      85701777 => 1100, # rs112
      85701778 => 2300, # rs226
      85701780 => 2300, # rs226
      85704329 => 1800, # a300j
      85704330 => 1800, # a300g
      85704328 => 2200, # tk1
      85709405 => 1380, # em1003
      85709404 => 1100, # ek1005
      85701779 => 4300, # rk86
      85664213 => (costs[0] * 2), # m2
      85664214 => (costs[1] * 28),  # k28
      85664217 => (costs[1] * 60),  # k60
      85664220 => (costs[1] * 90),  # k90
      85664215 => ((costs[0] * 1) + (costs[1] * 28)),  # s112
      85664216 => ((costs[0] * 2) + (costs[1] * 26)),  # s226
      85664221 => ((costs[0] * 3) + (costs[1] * 42))   # s342
    }
    est_sales_hash.include?(code) ? est_sales_hash[code] : 2000
  end

  def formatted_product_name
    # For reference the hash below was generated with with this nasty one-liner:
    # FurusatoOrder.all.pluck(:product_code, :product_name, :order_status).uniq.inject({})
    # {|m, a| m[a[0]] = [a[1],a[2]]; m }.
    # transform_keys(&:to_i).transform_values{|v| !v[1].to_i.zero? ? (v[0] + v[1]) : v[0]}
    name_hash = {
      85701774 => '冷凍牡蠣むき身500g×2',
      85709404 => '干えび(殻付) 100g×5',
      85704329 => '焼穴子 300g入(約5～8匹)ご家庭用 規',
      85664214 => '生牡蠣殻付28個',
      85704328 => 'ﾎﾞｲﾙたこ800g～1kg',
      85701775 => '冷凍牡蠣殻付27個',
      85701776 => '冷凍牡蠣むき身500g×1･殻付12個',
      85701779 => '冷凍牡蠣殻付86個',
      85664213 => '生牡蠣むき身500g×2',
      85701778 => '冷凍牡蠣むき身500g×2･殻付26個',
      85709405 => '干えび(ﾑｷ) 100g×3',
      85704330 => '焼穴子 300g入(約5～8匹)贈答用 規',
      85664217 => '生牡蠣殻付60個',
      85664215 => '生牡蠣むき身500g×1･殻付12個',
      85701777 => '冷凍牡蠣殻付56個',
      85664222 => '【3回】むき500g×1･殻付14個 頒12',
      85664220 => '生牡蠣殻付90個',
      85716408 => '生牡蠣殻付45個',
      85664216 => '生牡蠣むき身500g×2･殻付26個',
      85664218 => '【2回】むき500g×1･殻付13個 1月 頒1',
      85664223 => '【3回】むき500g×1･殻付14個 頒1'
    }
    name_hash.include?(code) ? name_hash[code] : '商品名登録されていない'
  end

  def count
    #     0          1           2         3        4      5      6     7    8        9       10      11       12
    # [nama_muki, nama_kara, shell_cards, p_muki, p_kara, anago, mebi, kebi, tako, barakara, salmon, sauce, tsukudani ]
    count_hash = {
      85701774 => [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0], # rm2
      85701775 => [0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0], # rk27
      85701776 => [0, 0, 0, 1, 12, 0, 0, 0, 0, 0, 0, 0, 0], # rs112
      85701777 => [0, 0, 0, 0, 56, 0, 0, 0, 0, 0, 0, 0, 0], # rs112
      85701778 => [0, 0, 0, 2, 26, 0, 0, 0, 0, 0, 0, 0, 0], # rs226
      85701780 => [0, 0, 0, 3, 42, 0, 0, 0, 0, 0, 0, 0, 0], # rs226
      85704329 => [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], # a300j
      85704330 => [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0], # a300g
      85704328 => [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], # tk1
      85709405 => [0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0], # em1003
      85709404 => [0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0], # ek1005
      85701779 => [0, 0, 0, 0, 86, 0, 0, 0, 0, 0, 0, 0, 0], # rk86
      85664213 => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # m2
      85664214 => [0, 28, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # k28
      85664217 => [0, 60, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # k60
      85664220 => [0, 90, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # k90
      85664215 => [1, 12, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # s112
      85664216 => [2, 26, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],  # s226
      85664221 => [3, 42, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]  # s342
    }
    count_hash.include?(code) ? count_hash[code] : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  end

  def knife?
    [85664214, 85664217, 85664220, 85664215, 85664216, 85664221].include?(code)
  end
end
