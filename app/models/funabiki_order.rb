class FunabikiOrder < ApplicationRecord
  belongs_to :stat, optional: true

  # Without a status the default scope will throw an error on every page using this ActiveRecord model
  validates :order_id, presence: true
  validates :order_id, uniqueness: true # Needs index

  # Return orders that includes pacakges that should be shipped today
  default_scope { where.not(ship_status: 'canceled') }
  scope :unfinished, -> { where(ship_status: 'pending') }
  scope :with_date, ->(date) { where(ship_date: [date]) }
  scope :with_dates, ->(date_range) { where(ship_date: date_range) }
  scope :this_season, -> { where(ship_date: ShopsHelper.this_season_start..ShopsHelper.this_season_end) }
  scope :prior_season, -> { where(ship_date: ShopsHelper.prior_season_start..ShopsHelper.prior_season_end) }
  scope :unprocessed, -> { unfinished.where('ship_date >= ?', Time.zone.today).reject(&:shipping_number?) }

  def self.with_shipping_number(number)
    all.select { |order| order.shipping_numbers.include?(number) }
  end

  def shipping_arrival_date
    arrival_date
  end

  def shipping_date
    ship_date
  end

  def shipping_numbers
    details['shipments'].map { |shipment| shipment['tracking'] }.compact
  end

  def shipping_number?
    shipping_numbers.present?
  end

  def url
    "https://funabiki.info/admin/orders/#{order_id}/edit"
  end

  def details
    JSON[data]
  end

  def completed_at
    DateTime.parse(details['completed_at'])
  end

  def billing_name
    details['bill_address']['name']
  end

  def shipping_name
    details['ship_address']['name']
  end

  def arrival_time
    details['arrival_time'].gsub(' ～ ', '-').gsub('時間指定なし', '指定なし')
  end

  def items
    details['line_items']
  end

  # Item ID for out purposes is the product slug with the variant id,
  # all line items have variants, even if they are the default variant
  def variant_id(variant)
    "f-#{variant['slug']}#{variant['id']}"
  end

  def item_ids_counts(exclude_knife: false)
    items.map do |item|
      variant = variant_id(item['variant'])
      next if exclude_knife && variant == 'f-oyster-knife104'

      [variant, item['quantity']]
    end.compact
  end

  def item_ids
    item_ids_counts.map(&:first)
  end

  def cancelled
    ship_status == 'canceled'
  end

  def knife_count
    item_ids_counts(exclude_knife: false).map { |(id, quantity)| quantity if id == 'f-oyster-knife104' }.compact.sum
  end

  def sauce_count
    item_ids_counts.compact.map { |(id, count)| count if id.include?('oyster-38') }.compact.sum
  end

  def tsukudani_count
    item_ids_counts.compact.map { |(id, count)| count if id.include?('oyster-tsukudani') }.compact.sum
  end

  def mukimi_sales_estimate
    0
  end

  def mukimi_profit_estimate
    0
  end

  def pack_profit_estimate
    0
  end

  def payments
    details['payments']
  end

  def payment_method
    payments.first['payment_method']['name']
  end

  def order_total
    details['total']
  end

  def total_price
    order_total.to_i
  end

  def print_daibiki
    payment_method.include?('代金引換決済') ? "代引き: ¥#{order_total}" : ''
  end

  def memo
    details['special_instructions']
  end
end
