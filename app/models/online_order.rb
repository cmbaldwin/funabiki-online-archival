class OnlineOrder < ApplicationRecord
  belongs_to :stat, optional: true

  validates :order_id, presence: true
  validates :order_id, uniqueness: true # Needs Index

  serialize :data

  default_scope { where.not(status: 'cancelled') }
  scope :this_season, -> { where(ship_date: ShopsHelper.this_season_start..ShopsHelper.this_season_end) }
  scope :prior_season, -> { where(ship_date: ShopsHelper.prior_season_start..ShopsHelper.prior_season_end) }
  scope :ship_search, ->(date) { where(ship_date: date) }
  scope :with_date, ->(dates) { where(ship_date: [dates]) }
  scope :with_dates, ->(date_range) { where(ship_date: date_range) }
  scope :shinki, -> { where(ship_date: nil, status: 'processing') }

  def cancelled
    status == 'cancelled'
  end

  def url
    "https://funabiki.info/wp-admin/post.php?post=#{order_id}&action=edit"
  end

  def shipping_lines
    data['shipping_lines']
  end

  def shipping_total
    data['shipping_total'].to_i
  end

  def calculate_extra_shipping
    shipping_lines.map { |eh| eh['total'].to_i + eh['total_tax'].to_i }.sum
  end

  def extra_shipping
    return shipping_total unless shipping_lines

    calculate_extra_shipping + shipping_total
  end

  def fee_lines
    data['fee_lines']
  end

  def calculate_extra_fee
    fee_lines.map { |eh| eh['total'].to_i + eh['total_tax'].to_i }.sum
  end

  def extra_fee
    return 0 unless fee_lines

    calculate_extra_fee
  end

  def total_price
    items.map { |i| i['total'].to_i }.sum + extra_shipping + extra_fee
  end

  def profit_estimate
    (total_price - expenses_estimate - raw_costs - shipping_estimate).to_i
  end

  def order_time
    DateTime.parse(data['date_created'])
  end

  def shipping_date
    ship_date || order_time.to_date
  end

  def has_frozen?(product_id)
    !item_count(product_id)[4..5].sum.zero?
  end

  def raw?(product_id)
    !(item_count(product_id)[0..2] + item_count(product_id)[6..10]).sum.zero?
  end

  def set?(count)
    !count[0].zero? && !count[1].zero?
  end

  def other?(count)
    !count[2..].sum.zero?
  end

  def tally_end_cells
    [
      arrival_date.to_s,
      arrival_time.nil? ? '' : arrival_time,
      ('代引き' if collect_order).to_s
    ]
  end

  def multiplier_string(string, quantity)
    string.insert(0, '(').insert(-1, ") x #{quantity}")
  end

  def print_frzn_tally_cell(quantity, count, idx, counter)
    return '' if count[idx].zero?

    cell = "#{count[idx]}#{counter}"
    return cell unless quantity > 1

    multiplier_string(cell, quantity)
  end

  def frozen_item_array(quantity, count)
    # ['#', '注文者', '届先', '冷凍 500g', '冷凍 セル', お届け日', '時間', '備考']
    # skip #, added via unshift on pdf creation
    [
      sender_name,
      unique_recipient ? recipient_name : '""',
      print_frzn_tally_cell(quantity, count, 3, 'p'),
      print_frzn_tally_cell(quantity, count, 4, '個')
    ].push(tally_end_cells)
  end

  # 0生むき身 1生セル 2小殻付 3冷凍むき身 4冷凍セル
  # 5穴子(件) 6穴子(g) 7干しムキエビ(100g) 8干し殻付エビ(100g) 9タコ
  def tally_frozen_items(print_items, item)
    product_id = item['product_id']
    count = item_count(product_id)
    count.delete_at(3) # Remove shell cards count
    quantity = item['quantity']
    print_items[:frozen] << frozen_item_array(quantity, count)
  end

  def raw_cell(count, idx, counter)
    "#{count[idx]}#{counter}"
  end

  def raw_set_cell(count)
    "500g#{count[0]} + #{count[1]}個"
  end

  def raw_other_cell(product_id)
    item_name(product_id)
  end

  def print_raw_tally_cell(quantity, count, idx, counter, bool)
    return '' if bool

    return '' if count[idx].zero?

    cell = "#{count[idx]}#{counter}"

    return cell unless quantity > 1

    multiplier_string(cell, quantity)
  end

  def raw_item_array(quantity, count, product_id)
    # ['#', '注文者', '届先', '500g', 'セル', 'セット', その他', 'お届け日', '時間', '備考']
    set_str = "500g#{count[0]} + #{count[1]}個"
    oth_str = item_name(product_id)
    [
      sender_name,
      (recipient_name if unique_recipient).to_s,
      print_raw_tally_cell(quantity, count, 0, 'p', set?(count)),
      print_raw_tally_cell(quantity, count, 1, '個', set?(count)),
      (multiplier_string(set_str, quantity) if set?(count)).to_s,
      (multiplier_string(oth_str, quantity) if other?(count)).to_s
    ].push(tally_end_cells)
  end

  # 0生むき身 1生セル 2小殻付 3冷凍むき身 4冷凍セル
  # 5穴子(件) 6穴子(g) 7干しムキエビ(100g) 8干し殻付エビ(100g) 9タコ
  def tally_raw_items(print_items, item)
    product_id = item['product_id']
    count = item_count(product_id)
    count.delete_at(3) # Remove shell cards count
    quantity = item['quantity']

    print_items[:raw] << raw_item_array(quantity, count, product_id)
  end

  def print_item_array
    print_items = { raw: [], frozen: [] }
    items.each do |item|
      if has_frozen?(item['product_id'])
        tally_frozen_items(print_items, item)
      else
        tally_raw_items(print_items, item)
      end
    end
    print_items
  end

  def online_shop_rate
    0.06 # Avg stripe, paypal, etc
  end

  def payment_method
    data['payment_method']
  end

  def shell_count
    counts[1]
  end

  def triploid_count
    counts[14]
  end

  def bara_count
    counts[2]
  end

  def mukimi_count
    counts[0]
  end

  def mukimi_ids
    [
      # mukimi
      583,
      581,
      580,
      579,
      578,
      577,
      6555,
      6556,
      6557,
      6558,
      6559,
      6560,
      # sets
      584,
      590,
      591,
      592,
      593,
      594
    ]
  end

  def mukimi_prices
    items.map do |item_hash|
      item_hash['price'] if mukimi_ids.include?(item_hash['product_id'])
    end
  end

  def mukimi_sales_estimate
    return 0 unless mukimi_count.positive?

    shell_sales_estimate = counts[1] * 100 # Est. -¥100/shell
    (mukimi_prices.compact.sum - shell_sales_estimate - expenses_estimate).to_i
  end

  def mukimi_per_pack_sales
    return 0 unless mukimi_count.positive?

    # Backup estimate for calculation errors (manual checks pervent sales loss)
    return 1200 unless mukimi_sales_estimate.positive?

    mukimi_sales_estimate / mukimi_count
  end

  def mukimi_profit_estimate
    return 0 unless mukimi_count.positive?

    mukimi_chrg_estimate = mukimi_sales_estimate * online_shop_rate
    raw_ovrhd = (raw_oyster_costs(shipping_date).values[0] + (60 * mukimi_count))
    (mukimi_sales_estimate - mukimi_chrg_estimate - raw_ovrhd).to_i
  end

  def pack_profit_estimate
    return 0 unless mukimi_count.positive?

    return 0 if mukimi_sales_estimate < 0

    mukimi_profit_estimate / mukimi_count
  end

  def raw_costs
    cost = 0
    costs = raw_oyster_costs(shipping_date).values
    items.each do |item_hash|
      item_id = item_hash['product_id']
      quantity = item_hash['quantity']
      # p "#{item_hash["name"]}: "
      item_raw_usage(item_id).each_with_index do |count, ci|
        # p "#{count} * #{quantity} * #{costs[ci]}" unless count.zero?
        cost += (count * quantity * costs[ci]).to_i unless count.zero?
      end
    end
    cost.to_i
  end

  def knife
    return 0 unless item_id_array.include?(500)

    quantity = items.map { |item| item['quantity'] if item['id'] == 500 }.first
    return 1 if quantity.nil?

    1 * quantity
  end

  def noshi
    return 0 unless item_id_array.include?(6319)

    quantity = items.map { |item| item['quantity'] if item['id'] == 6319 }.first
    return 1 if quantity.nil?

    1 * quantity
  end

  def items
    data['line_items']
  end

  def item_id_array
    items.map { |item| item['product_id'] }
  end

  def counts
    item_id_array.each_with_object(Array.new(15) { |_i| 0 }) do |item_id, memo|
      item_count(item_id).each_with_index do |c, i|
        (memo[i] += c) if memo[i] && c
      end
    end
  end

  def sender
    data['billing']
  end

  def sender_name
    sender['last_name'] + sender['first_name']
  end

  def get_meta(key)
    data['meta_data'].map { |meta_hash| meta_hash['value'] if meta_hash['key'] == key }.compact.first
  end

  def arrival_time
    get_meta('wc4jp-delivery-time-zone')
  end

  def recipient
    data['shipping']
  end

  def recipient_name
    recipient['last_name'] + recipient['first_name']
  end

  def unique_recipient
    (sender['address_1'] != recipient['address_1']) || (sender_name != recipient_name)
  end

  def status_jp
    {
      'processing' => '処理中',
      'cancelled' => 'キャンセル',
      'on-hold' => '保留中',
      'completed' => '完了'
    }[status]
  end

  def collect_order
    payment_method == 'cod'
  end

  def shipping_numbers
    get_meta('ywot_tracking_code')&.gsub(/[^0-9,.]/, '')&.scan(/.{1,12}/)
  end

  def expenses_estimate
    expenses = items.each.map { |item_hash| item_expenses(item_hash['product_id']) * item_hash['quantity'] }.sum
    charges = total_price * online_shop_rate
    (expenses + charges).to_i
  end

  def shipping_estimate
    basic_estimate = item_id_array.map do |item_id|
      box_size = item_id_to_yamato_box_size(item_id)
      calculate_shipping(prefecture, box_size)
    end
    return basic_estimate.sum.to_i unless collect_order

    (basic_estimate.sum + (shipping_numbers.count * 330)).to_i
  end

  def prefecture
    { 'JP01' => '北海道',
      'JP02' => '青森県',
      'JP03' => '岩手県',
      'JP04' => '宮城県',
      'JP05' => '秋田県',
      'JP06' => '山形県',
      'JP07' => '福島県',
      'JP08' => '茨城県',
      'JP09' => '栃木県',
      'JP10' => '群馬県',
      'JP11' => '埼玉県',
      'JP12' => '千葉県',
      'JP13' => '東京都',
      'JP14' => '神奈川県',
      'JP15' => '新潟県',
      'JP16' => '富山県',
      'JP17' => '石川県',
      'JP18' => '福井県',
      'JP19' => '山梨県',
      'JP20' => '長野県',
      'JP21' => '岐阜県',
      'JP22' => '静岡県',
      'JP23' => '愛知県',
      'JP24' => '三重県',
      'JP25' => '滋賀県',
      'JP26' => '京都府',
      'JP27' => '大阪府',
      'JP28' => '兵庫県',
      'JP29' => '奈良県',
      'JP30' => '和歌山県',
      'JP31' => '鳥取県',
      'JP32' => '島根県',
      'JP33' => '岡山県',
      'JP34' => '広島県',
      'JP35' => '山口県',
      'JP36' => '徳島県',
      'JP37' => '香川県',
      'JP38' => '愛媛県',
      'JP39' => '高知県',
      'JP40' => '福岡県',
      'JP41' => '佐賀県',
      'JP42' => '長崎県',
      'JP43' => '熊本県',
      'JP44' => '大分県',
      'JP45' => '宮崎県',
      'JP46' => '鹿児島県',
      'JP47' => '沖縄県' }[data['shipping']['state']]
  end

  def item_count(product_id)
    # %w{生むき身 生セル 小殻付 セルカード 冷凍むき身 冷凍セル 穴子(件) 穴子(g) 干しムキエビ(100g) 干し殻付エビ(100g) タコ サーモン ソース 佃煮 サムライゴールド}
    shells = {
      437 => [0, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      516 => [0, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      517 => [0, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      519 => [0, 40, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      520 => [0, 50, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      521 => [0, 60, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      838 => [0, 70, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      522 => [0, 80, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      837 => [0, 90, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      523 => [0, 100, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    triploid = {
      14_881 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10],
      14_893 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20],
      14_894 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30],
      14_895 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40],
      14_896 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50],
      14_897 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60],
      14_898 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70],
      14_899 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80],
      14_900 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90],
      14_901 => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100]
    }
    small_shells = {
      13_867 => [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_883 => [0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_884 => [0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_885 => [0, 0, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    mukimi = {
      583 => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      581 => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      580 => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      579 => [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      578 => [5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      577 => [6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6555 => [7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6556 => [8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6557 => [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6558 => [10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6559 => [11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6560 => [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    sets = {
      584 => [1, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      590 => [1, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      591 => [1, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      592 => [2, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      593 => [2, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      594 => [2, 40, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    dekapuri = {
      524 => [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      645 => [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      0 => [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      646 => [0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6554 => [0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_551 => [0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_552 => [0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    rshells = {
      13_585 => [0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_584 => [0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_583 => [0, 0, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_582 => [0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_580 => [0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_579 => [0, 0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_577 => [0, 0, 0, 0, 0, 70, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_586 => [0, 0, 0, 0, 0, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_587 => [0, 0, 0, 0, 0, 90, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_588 => [0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    other = {
      596 => [0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0],
      595 => [0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0],
      598 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0],
      599 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0],
      600 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0],
      597 => [0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0],
      572 => [0, 0, 0, 0, 0, 0, 1, 400, 0, 0, 0, 0, 0, 0, 0],
      575 => [0, 0, 0, 0, 0, 0, 1, 550, 0, 0, 0, 0, 0, 0, 0],
      576 => [0, 0, 0, 0, 0, 0, 1, 700, 0, 0, 0, 0, 0, 0, 0],
      13_641 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      14_238 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      500 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6319 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      14_252 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
      14_375 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
      14_418 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0],
      14_430 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0]
    }
    hashes = [shells, triploid, small_shells, mukimi, sets, dekapuri, rshells, other]
    all_items = hashes.inject(&:merge)
    all_items.key?(product_id) ? all_items[product_id] : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  end

  def item_raw_usage(item_id)
    # [nama_muki, nama_kara, p_muki, p_kara, anago, mebi, kebi, tako, barakara, salmon, sauce, tsukudani, triploid ]
    { # shells
      437 => [0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      516 => [0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      517 => [0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      519 => [0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      520 => [0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      521 => [0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      838 => [0, 70, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      522 => [0, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      837 => [0, 90, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      523 => [0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      # Triploid oysters
      14_881 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10],
      14_893 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20],
      14_894 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30],
      14_895 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40],
      14_896 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50],
      14_897 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60],
      14_898 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70],
      14_899 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80],
      14_900 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90],
      14_901 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100],
      # small shells
      13_867 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
      13_883 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0],
      13_884 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0],
      13_885 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0],
      # mukimi
      583 => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      581 => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      580 => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      579 => [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      578 => [5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      577 => [6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6555 => [7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6556 => [8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6557 => [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6558 => [10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6559 => [11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6560 => [12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      # sets
      584 => [1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      590 => [1, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      591 => [1, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      592 => [2, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      593 => [2, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      594 => [2, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      # dekapuri
      524 => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      645 => [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      0 => [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      646 => [0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      6554 => [0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_551 => [0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_552 => [0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      # rshells
      13_585 => [0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_584 => [0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_583 => [0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_582 => [0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_580 => [0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_579 => [0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_577 => [0, 0, 0, 70, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_586 => [0, 0, 0, 80, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_587 => [0, 0, 0, 90, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      13_588 => [0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      # other
      596 => [0, 0, 0, 0, 0, 0.300, 0, 0, 0, 0, 0, 0, 0], # me
      595 => [0, 0, 0, 0, 0, 0.500, 0, 0, 0, 0, 0, 0, 0],
      598 => [0, 0, 0, 0, 0, 0, 0.1000, 0, 0, 0, 0, 0, 0], # ke
      599 => [0, 0, 0, 0, 0, 0, 0.500, 0, 0, 0, 0, 0, 0],
      600 => [0, 0, 0, 0, 0, 0, 0.300, 0, 0, 0, 0, 0, 0],
      597 => [0, 0, 0, 0, 0, 0.200, 0.200, 0, 0, 0, 0, 0, 0], # ebset
      572 => [0, 0, 0, 0, 0.400, 0, 0, 0, 0, 0, 0, 0, 0], # anago
      575 => [0, 0, 0, 0, 0.550, 0, 0, 0, 0, 0, 0, 0, 0],
      576 => [0, 0, 0, 0, 0.700, 0, 0, 0, 0, 0, 0, 0, 0],
      13_641 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], # tako
      14_238 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
      500 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # knife
      6319 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # noshi
      14_252 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], # salmon
      14_375 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], # sauce
      14_418 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0], # tsukdani
      14_430 => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0]
    }[item_id]
  end

  def item_id_to_yamato_box_size(item_id)
    {
      584 => 80, # "むき身500g×1 + 殻付10個",
      590 => 80, # "むき身500g×1 + 殻付20個",
      591 => 100, # "むき身500g×1 + 殻付30個",
      592 => 100, # "むき身500g×2 + 殻付20個",
      593 => 100, # "むき身500g×2 + 殻付30個",
      594 => 100, # "むき身500g×2 + 殻付40個"

      437 => 60, # "殻付き 牡蠣10ヶ",
      516 => 80, # "殻付き 牡蠣20ヶ",
      517 => 80, # "殻付き 牡蠣30ヶ",
      519 => 80, # "殻付き 牡蠣40ヶ",
      520 => 100, # "殻付き 牡蠣50ヶ",
      521 => 100, # "殻付き 牡蠣60ヶ",
      838 => 100, # "殻付き 牡蠣70ヶ",
      522 => 100, # "殻付き 牡蠣80ヶ",
      837 => 100, # "殻付き 牡蠣90ヶ",
      523 => 100, # "殻付き 牡蠣100ヶ"

      14_881 => 60, # SBT 10
      14_893 => 80, # SBT 20
      14_894 => 80, # SBT 30
      14_895 => 100, # SBT 40
      14_896 => 100, # SBT 50
      14_897 => 100, # SBT 60
      14_898 => 100, # SBT 70
      14_899 => 100, # SBT 80
      14_900 => 100, # SBT 90
      14_901 => 100, # SBT 100

      583 => 80, # "生牡蠣むき身500g×1",
      581 => 80, # "生牡蠣むき身500g×2",
      580 => 80, # "生牡蠣むき身500g×3",
      579 => 100, # "生牡蠣むき身500g×4",
      578 => 100, # "生牡蠣むき身500g×5",
      577 => 100, # "生牡蠣むき身500g×6",
      6555 => 100, # "生牡蠣むき身500g×7",
      6556 => 100, # "生牡蠣むき身500g×8",
      6557 => 100, # "生牡蠣むき身500g×9",
      6558 => 100, # "生牡蠣むき身500g×10",
      6559 => 100, # "生牡蠣むき身500g×11",
      6560 => 100, # "生牡蠣むき身500g×12"

      13_585 => 60, # "冷凍 殻付き 牡蠣10ヶ",
      13_584 => 80, # "冷凍 殻付き 牡蠣20ヶ",
      13_583 => 80, # "冷凍 殻付き 牡蠣30ヶ",
      13_582 => 80, # "冷凍 殻付き 牡蠣40ヶ",
      13_580 => 100, # "冷凍 殻付き 牡蠣50ヶ",
      13_579 => 100, # "冷凍 殻付き 牡蠣60ヶ",
      13_577 => 100, # "冷凍 殻付き 牡蠣70ヶ",
      13_586 => 100, # "冷凍 殻付き 牡蠣80ヶ",
      13_587 => 100, # "冷凍 殻付き 牡蠣90ヶ",
      13_588 => 100, # "冷凍 殻付き 牡蠣100ヶ"

      524 => 80, # "冷凍 牡蠣むき身500g×1",
      645 => 80, # "冷凍 牡蠣むき身500g×2",
      0 => 80, # "冷凍 牡蠣むき身500g×2",
      646 => 80, # "冷凍 牡蠣むき身500g×3",
      6554 => 100, # "冷凍 牡蠣むき身500g×4",
      13_551 => 100, # "冷凍 牡蠣むき身500g×10",
      13_552 => 100, # "冷凍 牡蠣むき身500g×20"

      13_641 => 80, # "ボイルたこ (800g~1k)",
      14_238 => 80, # "ボイルたこ 約1kg (2~3匹)",

      596 => 60, # "干えび(ムキ) 100g×3袋",
      595 => 60, # "干えび(ムキ) 100g×5袋",
      598 => 60, # "干えび(殻付)100g×10袋",
      599 => 60, # "干えび(殻付)100g×5袋",
      600 => 60, # "干えび(殻付)100g×3袋",
      597 => 80, # "干えび(ムキ) 100g×2袋 + (殻付) 100g×2袋",

      572 => 60, # "焼穴子 400g入",
      575 => 60, # "焼穴子 550g入",
      576 => 60, # "焼穴子 700g入",

      13_867 => 60, # "小殻付き 1㎏",
      13_883 => 80, # "小殻付き 2㎏",
      13_884 => 80, # "小殻付き 3㎏",
      13_885 => 80, # "小殻付き 5㎏" }

      14_252 => 80, # "冷凍オイスターサーモン (400~600g１枚)",
      14_375 => 60, # "Oyster38 オイスターソース",

      14_418 => 60, # "サムライオイスター佃煮×3",
      14_430 => 80, # "サムライオイスター佃煮×6",
      500 => 0, # "牡蠣ナイフ" no charge,
      6319 => 0 # "熨斗" no charge }
    }[item_id]
  end

  def item_expenses(item_id)
    {
      584 => 360, # "むき身500g×1 + 殻付10個",
      590 => 360, # "むき身500g×1 + 殻付20個",
      591 => 300, # "むき身500g×1 + 殻付30個",
      592 => 360, # "むき身500g×2 + 殻付20個",
      593 => 360, # "むき身500g×2 + 殻付30個",
      594 => 360, # "むき身500g×2 + 殻付40個"

      437 => 150, # "殻付き 牡蠣10ヶ",
      516 => 180, # "殻付き 牡蠣20ヶ",
      517 => 180, # "殻付き 牡蠣30ヶ",
      519 => 230, # "殻付き 牡蠣40ヶ",
      520 => 250, # "殻付き 牡蠣50ヶ",
      521 => 250, # "殻付き 牡蠣60ヶ",
      838 => 250, # "殻付き 牡蠣70ヶ",
      522 => 280, # "殻付き 牡蠣80ヶ",
      837 => 280, # "殻付き 牡蠣90ヶ",
      523 => 280, # "殻付き 牡蠣100ヶ"

      14_881 => 150, # SBT 10
      14_893 => 180, # SBT 20
      14_894 => 180, # SBT 30
      14_895 => 230, # SBT 40
      14_896 => 250, # SBT 50
      14_897 => 250, # SBT 60
      14_898 => 250, # SBT 70
      14_899 => 280, # SBT 80
      14_900 => 280, # SBT 90
      14_901 => 280, # SBT 100

      583 => 250, # "生牡蠣むき身500g×1",
      581 => 310, # "生牡蠣むき身500g×2",
      580 => 425, # "生牡蠣むき身500g×3",
      579 => 490, # "生牡蠣むき身500g×4",
      578 => 550, # "生牡蠣むき身500g×5",
      577 => 610, # "生牡蠣むき身500g×6",
      6555 => 660, # "生牡蠣むき身500g×7",
      6556 => 720, # "生牡蠣むき身500g×8",
      6557 => 780, # "生牡蠣むき身500g×9",
      6558 => 840, # "生牡蠣むき身500g×10",
      6559 => 900, # "生牡蠣むき身500g×11",
      6560 => 960, # "生牡蠣むき身500g×12"

      13_585 => 150, # "冷凍 殻付き 牡蠣10ヶ",
      13_584 => 180, # "冷凍 殻付き 牡蠣20ヶ",
      13_583 => 180, # "冷凍 殻付き 牡蠣30ヶ",
      13_582 => 230, # "冷凍 殻付き 牡蠣40ヶ",
      13_580 => 250, # "冷凍 殻付き 牡蠣50ヶ",
      13_579 => 250, # "冷凍 殻付き 牡蠣60ヶ",
      13_577 => 250, # "冷凍 殻付き 牡蠣70ヶ",
      13_586 => 280, # "冷凍 殻付き 牡蠣80ヶ",
      13_587 => 280, # "冷凍 殻付き 牡蠣90ヶ",
      13_588 => 280, # "冷凍 殻付き 牡蠣100ヶ"

      524 => 230, # "冷凍 牡蠣むき身500g×1",
      645 => 250, # "冷凍 牡蠣むき身500g×2",
      0 => 250, # "冷凍 牡蠣むき身500g×2",
      646 => 325, # "冷凍 牡蠣むき身500g×3",
      6554 => 350, # "冷凍 牡蠣むき身500g×4",
      13_551 => 500, # "冷凍 牡蠣むき身500g×10",
      13_552 => 750, # "冷凍 牡蠣むき身500g×20"

      13_641 => 180, # "ボイルたこ (800g~1k)",
      14_238 => 180, # "ボイルたこ 約1kg (2~3匹)",

      596 => 300, # "干えび(ムキ) 100g×3袋",
      595 => 300, # "干えび(ムキ) 100g×5袋",
      598 => 300, # "干えび(殻付)100g×10袋",
      599 => 300, # "干えび(殻付)100g×5袋",
      600 => 300, # "干えび(殻付)100g×3袋",
      597 => 400, # "干えび(ムキ) 100g×2袋 + (殻付) 100g×2袋",

      572 => 400, # "焼穴子 400g入",
      575 => 300, # "焼穴子 550g入",
      576 => 300, # "焼穴子 700g入",

      13_867 => 150, # "小殻付き 1㎏",
      13_883 => 150, # "小殻付き 2㎏",
      13_884 => 200, # "小殻付き 3㎏",
      13_885 => 200, # "小殻付き 5㎏" }

      14_252 => 200, # "冷凍オイスターサーモン (400~600g１枚)",
      14_375 => 400, # "Oyster38 オイスターソース",

      14_418 => 600, # "サムライオイスター佃煮×3",
      14_430 => 120, # "サムライオイスター佃煮×6",
      500 => 180, # "牡蠣ナイフ",
      6319 => 15 # "熨斗" }
    }[item_id]
  end

  def item_name(item_id)
    shells = {
      437 => '殻付き 牡蠣10ヶ',
      516 => '殻付き 牡蠣20ヶ',
      517 => '殻付き 牡蠣30ヶ',
      519 => '殻付き 牡蠣40ヶ',
      520 => '殻付き 牡蠣50ヶ',
      521 => '殻付き 牡蠣60ヶ',
      838 => '殻付き 牡蠣70ヶ',
      522 => '殻付き 牡蠣80ヶ',
      837 => '殻付き 牡蠣90ヶ',
      523 => '殻付き 牡蠣100ヶ'
    }
    sbt = {
      14_881 => '三倍体 殻付き 牡蠣10ヶ',
      14_893 => '三倍体 殻付き 牡蠣20ヶ',
      14_894 => '三倍体 殻付き 牡蠣30ヶ',
      14_895 => '三倍体 殻付き 牡蠣40ヶ',
      14_896 => '三倍体 殻付き 牡蠣50ヶ',
      14_897 => '三倍体 殻付き 牡蠣60ヶ',
      14_898 => '三倍体 殻付き 牡蠣70ヶ',
      14_899 => '三倍体 殻付き 牡蠣80ヶ',
      14_900 => '三倍体 殻付き 牡蠣90ヶ',
      14_901 => '三倍体 殻付き 牡蠣100ヶ'

    }
    small_shells = {
      13_867 => '小殻付き 1㎏',
      13_883 => '小殻付き 2㎏',
      13_884 => '小殻付き 3㎏',
      13_885 => '小殻付き 5㎏'
    }
    mukimi = {
      583 => '生牡蠣むき身500g×1',
      581 => '生牡蠣むき身500g×2',
      580 => '生牡蠣むき身500g×3',
      579 => '生牡蠣むき身500g×4',
      578 => '生牡蠣むき身500g×5',
      577 => '生牡蠣むき身500g×6',
      6555 => '生牡蠣むき身500g×7',
      6556 => '生牡蠣むき身500g×8',
      6557 => '生牡蠣むき身500g×9',
      6558 => '生牡蠣むき身500g×10',
      6559 => '生牡蠣むき身500g×11',
      6560 => '生牡蠣むき身500g×12'
    }
    sets = {
      584 => 'むき身500g×1 + 殻付10個',
      590 => 'むき身500g×1 + 殻付20個',
      591 => 'むき身500g×1 + 殻付30個',
      592 => 'むき身500g×2 + 殻付20個',
      593 => 'むき身500g×2 + 殻付30個',
      594 => 'むき身500g×2 + 殻付40個'
    }
    dekapuri = {
      524 => '冷凍 牡蠣むき身500g×1',
      645 => '冷凍 牡蠣むき身500g×2',
      0 => '冷凍 牡蠣むき身500g×2',
      646 => '冷凍 牡蠣むき身500g×3',
      6554 => '冷凍 牡蠣むき身500g×4',
      13_551 => '冷凍 牡蠣むき身500g×10',
      13_552 => '冷凍 牡蠣むき身500g×20'
    }
    rshells = {
      13_585 => '冷凍 殻付き 牡蠣10ヶ',
      13_584 => '冷凍 殻付き 牡蠣20ヶ',
      13_583 => '冷凍 殻付き 牡蠣30ヶ',
      13_582 => '冷凍 殻付き 牡蠣40ヶ',
      13_580 => '冷凍 殻付き 牡蠣50ヶ',
      13_579 => '冷凍 殻付き 牡蠣60ヶ',
      13_577 => '冷凍 殻付き 牡蠣70ヶ',
      13_586 => '冷凍 殻付き 牡蠣80ヶ',
      13_587 => '冷凍 殻付き 牡蠣90ヶ',
      13_588 => '冷凍 殻付き 牡蠣100ヶ'
    }
    other = {
      596 => '干えび(ムキ) 100g×3袋',
      595 => '干えび(ムキ) 100g×5袋',
      598 => '干えび(殻付)100g×10袋',
      599 => '干えび(殻付)100g×5袋',
      600 => '干えび(殻付)100g×3袋',
      597 => '干えび(ムキ) 100g×2袋 + (殻付) 100g×2袋',
      13_641 => 'ボイルたこ (800g~1k)',
      14_238 => 'ボイルたこ 約1kg (2~3匹)',
      572 => '焼穴子 400g入',
      575 => '焼穴子 550g入',
      576 => '焼穴子 700g入',
      14_252 => '冷凍オイスターサーモン (400~600g１枚)',
      14_375 => 'Oyster38 オイスターソース',
      14_418 => 'サムライオイスター佃煮×3',
      14_430 => 'サムライオイスター佃煮×6',
      500 => '牡蠣ナイフ',
      6319 => '熨斗'
    }
    hashes = [shells, sbt, small_shells, mukimi, sets, dekapuri, rshells, other]
    all_items = hashes.inject(&:merge)
    all_items.key?(item_id) ? all_items[item_id] : '???'
  end
end
