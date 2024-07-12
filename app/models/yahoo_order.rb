class YahooOrder < ApplicationRecord
  belongs_to :stat, optional: true

  validates_presence_of :order_id
  validates_uniqueness_of :order_id

  serialize :details, type: Hash

  default_scope { where.not(order_status: '4') }
  scope :this_season, -> { where(ship_date: ShopsHelper.this_season_start..ShopsHelper.this_season_end) }
  scope :prior_season, -> { where(ship_date: ShopsHelper.prior_season_start..ShopsHelper.prior_season_end) }
  scope :with_date, ->(date) { where(ship_date: [date]) }
  scope :with_dates, ->(date_range) { where(ship_date: date_range) }
  scope :undated, -> { where(ship_date: nil) }
  scope :processing, -> { where(order_status: %w[1 2]) }

  def data_order_time
    DateTime.parse(details['OrderTime'])
  end

  def print_order_status
    return unless order_status

    print_status = { 1 => '予約中', 2 => '処理中', 3 => '保留', 4 => 'キャンセル', 5 => '完了' }
    print_status[order_status.to_i]
  end

  def store_status
    details['StoreStatus']
  end

  def billing_address
    billing_details['BillPrefecture'] + billing_details['BillCity'] + billing_details['BillAddress1']
  end

  def shipping_address
    shipping_details['ShipPrefecture'] + shipping_details['ShipCity'] + shipping_details['ShipAddress1']
  end

  def same_sender
    billing_address == shipping_address
  end

  def collect_order
    payment_type == '商品代引'
  end

  def cancelled
    order_status == '4'
  end

  def print_shipping_status
    return unless shipping_status

    print_status = { 1 => '決済申込', 2 => '支払待ち', 3 => '支払完了', 4 => '入金待ち', 5 => '決済完了', 6 => 'キャンセル', 7 => '返金',
                     8 => '有効期限切れ', 9 => '決済申込中', 10 => 'オーソリエラー', 11 => '売上取消', 12 => 'Suicaアドレスエラー' }
    print_status[shipping_status.to_i]
  end

  def shipping_date
    # always return a date
    ship_date || order_time.to_date
  end

  def total_price
    details['Detail']['TotalPrice'].to_i # returns 0 if paid by points--going to have to estimate sales here
  end

  def url
    'https://pro.store.yahoo.co.jp/pro.oystersisters/order/manage/detail/' + order_id
  end

  def contact_url
    'https://pro.store.yahoo.co.jp/pro.oystersisters/order/manage/detail/mail_and_form/' + order_id
  end

  def yahoo_id
    details['OrderId']
  end

  def billing_name
    details['Pay']['BillLastName'] + ' ' + details['Pay']['BillFirstName'] if details['Pay']
  end

  def billing_name_kana
    details['Pay']['BillLastNameKana'] + ' ' + details['Pay']['BillFirstNameKana']
  end

  def yamato_fix_billing_address
    if same_sender || collect_order
      '兵庫県赤穂市中広1576−11'
    else
      billing_details['BillPrefecture'] + billing_details['BillCity'] + billing_details['BillAddress1']
    end
  end

  def yamato_fix_billing_name
    if same_sender || collect_order
      'Oyster Sisters'
    else
      billing_name
    end
  end

  def yamato_fix_billing_name_kana
    if same_sender || collect_order
      'ｵｲｽﾀｰｼｽﾀｰｽﾞ'
    else
      Moji.zen_to_han(billing_name_kana)
    end
  end

  def yamato_fix_billing_phone
    if same_sender || collect_order
      '0791436556'
    else
      billing_phone
    end
  end

  def yamato_fix_billing_address2
    if same_sender || collect_order
      ''
    else
      billing_details['BillAddress2']
    end
  end

  def yamato_fix_billing_zip
    if same_sender || collect_order
      '6780232'
    else
      billing_details['BillZipCode']
    end
  end

  def billing_phone
    shipping_details['BillPhoneNumber']
  end

  def item_options
    details = item_details
    if details.is_a?(Hash)
      [details['ItemOption']]
    else # it's an array of hashes
      details.map { |i| i['ItemOption'] }
    end
  end

  def price_estimate
    pay_details = YahooOrder.last.details['Detail']
    item_prices = item_ids.each_with_index.map { |item_id, i| item_price(item_id) * quantities[i].to_i }.sum
    item_prices + pay_details['PayCharge'].to_i + pay_details['ShipCharge'].to_i + pay_details['GiftWrapCharge'].to_i
  end

  def yahoo_rate
    0.06
  end

  def profit_estimate
    (price_estimate.to_i - expenses_estimate - raw_costs - shipping_estimate).to_i
  end

  def expenses_estimate
    expenses = item_ids.each_with_index.map { |item, i| item_expenses(item).to_i * quantities[i].to_i }.sum
    charges = price_estimate.to_i * yahoo_rate
    (expenses + charges).to_i
  end

  def shipping_numbers
    [shipping_details['ShipInvoiceNumber1'], shipping_details['ShipInvoiceNumber2']].uniq.compact
  end

  def raw_costs
    cost = 0
    costs = raw_oyster_costs(shipping_date).values
    item_ids.each_with_index do |item_id, i|
      item_raw_usage(item_id).each_with_index do |count, ci|
        cost += (count * quantities[i].to_i * costs[ci]) unless count.zero?
      end
    end
    cost.to_i
  end

  def shipping_estimate
    basic_estimate = item_ids.map do |item_id|
      calculate_shipping(shipping_details['ShipPrefecture'], item_id_to_yamato_box_size(item_id))
    end.sum
    collect_order ? (basic_estimate + (shipping_numbers.count * 330)).to_i : basic_estimate.to_i
  end

  def mukimi_sales_estimate
    if mukimi_count > 0
      relevant_ids = %w[
        mukimi04
        mukimi03
        mukimi02
        mukimi01
        kakiset302
        kakiset202
        kakiset301
        kakiset201
        kakiset101
      ]
      relevant_sales = item_ids.each_with_index.map do |item_id, _i|
        item_price(item_id) if relevant_ids.include?(item_id)
      end.compact.sum
      shell_sales_estimate = counts[1] * 100 # 100 yen per shell
      (relevant_sales - shell_sales_estimate - expenses_estimate - shipping_estimate)
    else
      0
    end
  end

  def mukimi_per_pack_sales
    if mukimi_count > 0
      mukimi_sales_estimate / mukimi_count
    else
      0
    end
  end

  def mukimi_profit_estimate
    if mukimi_count > 0
      mukimi_charges_estimate = mukimi_sales_estimate * yahoo_rate
      (mukimi_sales_estimate - mukimi_charges_estimate - (raw_oyster_costs(shipping_date).values[0] + (60 * mukimi_count))).to_i
    else
      0
    end
  end

  def pack_profit_estimate
    if mukimi_count > 0
      mukimi_profit_estimate / mukimi_count
    else
      0
    end
  end

  def item_count
    counts.sum
  end

  def knife_count
    item_options.compact.flatten.map do |o|
      if o['Name'].include?('ナイフ')
        o['Value'].include?('あり') ? 1 : 0
      else
        0
      end
    end.sum
  end

  def tsukudani_count
    item_options.compact.flatten.map do |o|
      if o['Name'].include?('佃煮')
        o['Value'].include?('希望') ? 1 : 0
      else
        0
      end
    end.sum
  end

  def sauce_count
    item_options.compact.flatten.map do |o|
      if o['Name'].include?('Oyster38')
        o['Value'].include?('希望') ? 1 : 0
      else
        0
      end
    end.sum
  end

  def shipping_name
    "#{shipping_details['ShipLastName']} #{shipping_details['ShipFirstName']}"
  end

  def shipping_name_kana
    "#{shipping_details['ShipLastNameKana']} #{shipping_details['ShipFirstNameKana']}"
  end

  def shipping_details
    details['Ship']
  end

  def shipping_phone
    shipping_details['ShipPhoneNumber']
  end

  def billing_details
    details['Pay']
  end

  def item_details
    details['Item']
  end

  def item_ids_counts
    case item_details
    when Hash
      [[item_details['ItemId'], item_details['Quantity'].to_i]]
    when Array
      item_details.map { |item| [item['ItemId'], item['Quantity'].to_i] }
    end
  end

  def item_ids
    case item_details
    when Hash
      [item_details['ItemId']]
    when Array
      item_details.map { |item| item['ItemId'] }
    end
  end

  def quantities
    case item_details
    when Hash
      item_details ? [item_details['Quantity']] : ['0']
    when Array
      item_details.map { |item| item['Quantity'] }
    end
  end

  def print_quantity(i)
    quantities[i].to_i > 1 ? (' × ' + quantities[i]) : ''
  end

  def shipping_address(for_print = false)
    address = { prefecture: shipping_details['ShipPrefecture'], city: shipping_details['ShipCity'],
                address1: shipping_details['ShipAddress1'], address2: shipping_details['ShipAddress2'], phone: shipping_details['ShipPhoneNumber'] }
    for_print ? (address.each { |_k, v| (v + "\n") unless v.nil? }) : address
  end

  def billing_address(for_print = false)
    address = { prefecture: billing_details['BillPrefecture'], city: billing_details['BillCity'],
                address1: billing_details['BillAddress1'], address2: billing_details['BillAddress2'], phone: billing_details['BillPhoneNumber'] }
    for_print ? (address.each { |_k, v| (v + "\n") unless v.nil? }) : address
  end

  def shipping_type
    # if it's collect set to 2
    billing_details['PayMethod'] == 'payment_d1' ? '2' : '0'
  end

  def print_daibiki
    return unless payment_type == '商品代引'

    " 代引：¥#{total_price}"
  end

  def shipping_arrival_date
    two_day_prefectures = %W[\u5317\u6D77\u9053 \u9752\u68EE\u770C \u79CB\u7530\u770C \u5CA9\u624B\u770C
                             \u9577\u5D0E\u770C \u6C96\u7E04\u770C \u9E7F\u5150\u5CF6\u770C]
    parsed_ship_date = ship_date.nil? ? Time.zone.today : ship_date
    if shipping_details['ShipRequestDate']
      Date.parse(shipping_details['ShipRequestDate'])
    elsif two_day_prefectures.include?(shipping_details['ShipPrefecture'])
      (parsed_ship_date + 2.day)
    else
      (parsed_ship_date + 1.day)
    end
  end

  def yamato_arrival_time
    req_time = shipping_details['ShipRequestTime']
    if req_time
      conversion_hash = {
        '08:00-12:00' => '0812',
        '09:00-12:00' => '0812',
        '14:00-16:00' => '1416',
        '16:00-18:00' => '1618',
        '18:00-20:00' => '1820',
        '19:00-21:00' => '1921'
      }
      conversion_hash.keys.include?(req_time) ? conversion_hash[req_time] : req_time
    else
      ''
    end
  end

  def arrival_time
    (shipping_details['ShipRequestTime'].nil? ? '指定無し' : shipping_details['ShipRequestTime'])
  end

  def tracking
    shipping_details['ShipInvoiceNumber1']
  end

  def tracking_url
    'https://jizen.kuronekoyamato.co.jp/jizen/servlet/crjz.b.NQ0010?id=' + tracking
  end

  def counts
    counts_array = []
    # Rakuten for comparison, bara needs to be dropped after index 1 for combinination, and get rid of anago-ken
    #                  0      1    2       3       4       5      6       7          8                9         10    11       12       13          14
    # types_arr = %w{生むき身 生セル 小殻付 セルカード 冷凍むき身 冷凍セル 穴子(件) 穴子(g) 干しムキエビ(80g) 干し殻付エビ(80g) タコ サーモン Oyster38 サムライ佃煮 サムライゴールド}
    count_hash = {
      'kakiset302' => [2, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset202' => [2, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset301' => [1, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset201' => [1, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'kakiset101' => [1, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki100' => [0, 100, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki50' => [0, 50, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki40' => [0, 40, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki30' => [0, 30, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki20' => [0, 20, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'karatsuki10' => [0, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi04' => [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi03' => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi02' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'mukimi01' => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara100' => [0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara50' => [0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara40' => [0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara30' => [0, 0, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara20' => [0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pkara10' => [0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki04' => [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki03' => [0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki02' => [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'pmuki01' => [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'tako1k' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      'tako1k2-3b' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
      'mebi80x5' => [0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0],
      'mebi80x3' => [0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0],
      'hebi80x10' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0],
      'hebi80x5' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0],
      'anago600' => [0, 0, 0, 0, 0, 0, 1, 600, 0, 0, 0, 0, 0, 0, 0],
      'anago480' => [0, 0, 0, 0, 0, 0, 1, 480, 0, 0, 0, 0, 0, 0, 0],
      'anago350' => [0, 0, 0, 0, 0, 0, 1, 350, 0, 0, 0, 0, 0, 0, 0],
      'syoukara1kg' => [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'syoukara2kg' => [0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'syoukara3kg' => [0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'syoukara5kg' => [0, 0, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      'reoysalmon' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
      'oyster38' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
      'tsukudani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0],
      'tsukuani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0], # typo...
      'tsukuani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0], # typo...
      'tsukudani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0], # Tsukud6
      'sbt-10' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10], # sbt10
      'sbt-20' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20], # sbt20
      'sbt-30' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30], # sbt30
      'sbt-40' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40], # sbt40
      'sbt-50' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50], # sbt50
      'sbt-60' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60], # sbt60
      'sbt-70' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70], # sbt70
      'sbt-80' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80], # sbt80
      'sbt-90' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90], # sbt90
      'sbt-100' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100] # sbt100
    }
    item_ids.each do |item_id|
      if counts_array.empty?
        counts_array = count_hash[item_id]
      else
        new_counts = count_hash[item_id]
        counts_array.each_with_index { |c, i| c += new_counts[i] }
      end
    end
    counts_array
  end

  def item_raw_usage(item_id)
    { # [nama_muki, nama_kara, p_muki, p_kara, anago, mebi, kebi, tako, barakara, salmon, sauce, tsukudani, triploid ]
      'mukimi01' => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m1
      'mukimi02' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m2
      'mukimi03' => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m3
      'mukimi04' => [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m4
      'pmuki01' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p1
      'pmuki02' => [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p2
      'pmuki03' => [0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p3
      'pmuki04' => [0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p4
      'karatsuki10' => [0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k10
      'karatsuki20' => [0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k20
      'karatsuki30' => [0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k30
      'karatsuki40' => [0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k40
      'karatsuki50' => [0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k50
      'karatsuki100' => [0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k100
      'pkara10' => [0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk10
      'pkara20' => [0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk20
      'pkara30' => [0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk30
      'pkara40' => [0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk40
      'pkara50' => [0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk50
      'pkara100' => [0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk100
      'kakiset101' => [1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s110
      'kakiset201' => [1, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s120
      'kakiset301' => [1, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s130
      'kakiset202' => [2, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s220
      'kakiset302' => [2, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s230
      'anago350' => [0, 0, 0, 0, 0.350, 0, 0, 0, 0, 0, 0, 0, 0], # a350
      'anago480' => [0, 0, 0, 0, 0.480, 0, 0, 0, 0, 0, 0, 0, 0], # a480
      'anago600' => [0, 0, 0, 0, 0.600, 0, 0, 0, 0, 0, 0, 0, 0], # a560
      'mebi80x5' => [0, 0, 0, 0, 0, 0.400, 0, 0, 0, 0, 0, 0, 0], # em1
      'mebi80x3' => [0, 0, 0, 0, 0, 0.240, 0, 0, 0, 0, 0, 0, 0], # em2
      'hebi80x10' => [0, 0, 0, 0, 0, 0, 0.400, 0, 0, 0, 0, 0, 0], # kem1
      'hebi80x5' => [0, 0, 0, 0, 0, 0, 0.800, 0, 0, 0, 0, 0, 0], # kem2
      'syoukara1kg' => [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], # bkar1
      'syoukara2kg' => [0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0], # bkar2
      'syoukara3kg' => [0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0], # bkar3
      'syoukara5kg' => [0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0], # bkar5
      'tako1k' => [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0], # tako
      'tako1k2-3b' => [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0], # tako
      'reoysalmon' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], # salmon
      'oyster38' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], # oyster38
      'tsukudani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3], # tsukudani3
      'tsukuani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3], # tsukudani3
      'tsukuani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3], # tsukudani3
      'tsukudani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6], # Tsukud6
      'sbt-10' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10], # sbt10
      'sbt-20' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20], # sbt20
      'sbt-30' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30], # sbt30
      'sbt-40' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40], # sbt40
      'sbt-50' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50], # sbt50
      'sbt-60' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60], # sbt60
      'sbt-70' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70], # sbt70
      'sbt-80' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80], # sbt80
      'sbt-90' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90], # sbt90
      'sbt-100' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100] # sbt100
    }[item_id]
  end

  def item_price(item_id)
    {
      'kakiset302' => 8800,
      'kakiset202' => 7700,
      'kakiset301' => 7000,
      'kakiset201' => 5800,
      'kakiset101' => 4500,
      'karatsuki100' => 150_000,
      'karatsuki50' => 8500,
      'karatsuki40' => 7700,
      'karatsuki30' => 5500,
      'karatsuki20' => 4400,
      'karatsuki10' => 2800,
      'mukimi04' => 9200,
      'mukimi03' => 7200,
      'mukimi02' => 5000,
      'mukimi01' => 3300,
      'pkara100' => 15_000,
      'pkara50' => 7800,
      'pkara40' => 6500,
      'pkara30' => 5200,
      'pkara20' => 4000,
      'pkara10' => 2600,
      'pmuki04' => 6500,
      'pmuki03' => 5100,
      'pmuki02' => 3900,
      'pmuki01' => 2600,
      'tako1k' => 4200,
      'tako1k2-3b' => 3500,
      'mebi80x5' => 5700,
      'mebi80x3' => 3800,
      'hebi80x10' => 5800,
      'hebi80x5' => 3300,
      'anago600' => 8400,
      'anago480' => 7000,
      'anago350' => 5500,
      'syoukara1kg' => 2500,
      'syoukara2kg' => 3600,
      'syoukara3kg' => 4700,
      'syoukara5kg' => 6500,
      'reoysalmon' => 3300,
      'oyster38' => 2800,
      'tsukudani' => 2600,
      'tsukuani' => 2600,
      'tsukuani6' => 4000,
      'tsukudani6' => 4000,
      'sbt-10' => 3800,
      'sbt-20' => 6100,
      'sbt-30' => 8400,
      'sbt-40' => 10_800,
      'sbt-50' => 13_000,
      'sbt-60' => 15_300,
      'sbt-70' => 17_600,
      'sbt-80' => 19_900,
      'sbt-90' => 22_200,
      'sbt-100' => 24_400
    }[item_id]
  end

  def item_expenses(item_id)
    {
      'kakiset302' => 360,
      'kakiset202' => 360,
      'kakiset301' => 300,
      'kakiset201' => 250,
      'kakiset101' => 360,
      'karatsuki100' => 280,
      'karatsuki50' => 250,
      'karatsuki40' => 230,
      'karatsuki30' => 180,
      'karatsuki20' => 180,
      'karatsuki10' => 150,
      'mukimi04' => 490,
      'mukimi03' => 425,
      'mukimi02' => 310,
      'mukimi01' => 250,
      'pkara100' => 280,
      'pkara50' => 250,
      'pkara40' => 230,
      'pkara30' => 180,
      'pkara20' => 180,
      'pkara10' => 150,
      'pmuki04' => 330,
      'pmuki03' => 255,
      'pmuki02' => 230,
      'pmuki01' => 205,
      'tako1k' => 180,
      'tako1k2-3b' => 180,
      'mebi80x5' => 300,
      'mebi80x3' => 300,
      'hebi80x10' => 300,
      'hebi80x5' => 300,
      'anago600' => 400,
      'anago480' => 300,
      'anago350' => 300,
      'syoukara1kg' => 150,
      'syoukara2kg' => 150,
      'syoukara3kg' => 200,
      'syoukara5kg' => 200,
      'reoysalmon' => 200,
      'oyster38' => 400,
      'tsukudani' => 600,
      'tsukuani' => 600,
      'tsukuani6' => 1200,
      'tsukudani6' => 1200,
      'sbt-10' => 150,
      'sbt-20' => 180,
      'sbt-30' => 180,
      'sbt-40' => 230,
      'sbt-50' => 250,
      'sbt-60' => 250,
      'sbt-70' => 250,
      'sbt-80' => 250,
      'sbt-90' => 300,
      'sbt-100' => 300
    }[item_id]
  end

  def item_id_to_yamato_box_size(item_id)
    {
      'kakiset302' => 100,
      'kakiset202' => 100,
      'kakiset301' => 100,
      'kakiset201' => 80,
      'kakiset101' => 80,
      'karatsuki100' => 100,
      'karatsuki50' => 100,
      'karatsuki40' => 80,
      'karatsuki30' => 80,
      'karatsuki20' => 80,
      'karatsuki10' => 60,
      'mukimi04' => 100,
      'mukimi03' => 100,
      'mukimi02' => 80,
      'mukimi01' => 80,
      'pkara100' => 100,
      'pkara50' => 100,
      'pkara40' => 80,
      'pkara30' => 80,
      'pkara20' => 80,
      'pkara10' => 60,
      'pmuki04' => 100,
      'pmuki03' => 80,
      'pmuki02' => 80,
      'pmuki01' => 80,
      'tako1k' => 80,
      'tako1k2-3b' => 80,
      'mebi80x5' => 60,
      'mebi80x3' => 60,
      'hebi80x10' => 60,
      'hebi80x5' => 60,
      'anago600' => 60,
      'anago480' => 60,
      'anago350' => 60,
      'syoukara1kg' => 60,
      'syoukara2kg' => 80,
      'syoukara3kg' => 80,
      'syoukara5kg' => 80,
      'reoysalmon' => 80,
      'oyster38' => 60,
      'tsukuani' => 60,
      'tsukudani' => 60,
      'tsukuani6' => 80,
      'tsukudani6' => 80,
      'sbt-10' => 60,
      'sbt-20' => 80,
      'sbt-30' => 80,
      'sbt-40' => 100,
      'sbt-50' => 100,
      'sbt-60' => 100,
      'sbt-70' => 100,
      'sbt-80' => 100,
      'sbt-90' => 100,
      'sbt-100' => 100
    }[item_id]
  end

  def section(section_name)
    sections = {
      '水切り' => [
        'mukimi01', # m1
        'mukimi02', # m2
        'mukimi03', # m3
        'mukimi04' # m4
      ],
      'セル' => %w[
        karatsuki100
        karatsuki50
        karatsuki40
        karatsuki30
        karatsuki20
        karatsuki10
      ],
      '三倍体' => %w[
        sbt-10
        sbt-20
        sbt-30
        sbt-40
        sbt-50
        sbt-60
        sbt-70
        sbt-80
        sbt-90
        sbt-100
      ],
      '小セル' => %w[
        syoukara1kg
        syoukara2kg
        syoukara3kg
        syoukara5kg
      ],
      'セット' => %w[
        kakiset302
        kakiset202
        kakiset301
        kakiset201
        kakiset101
      ],
      'デカプリ' => %w[
        pmuki04
        pmuki03
        pmuki02
        pmuki01
      ],
      '冷凍セル' => %w[
        pkara100
        pkara50
        pkara40
        pkara30
        pkara20
        pkara10
      ],
      '焼き穴子' => %w[
        anago600
        anago480
        anago350
      ],
      '干し海老' => %w[
        mebi80x5
        mebi80x3
        hebi80x10
        hebi80x5
      ],
      'タコ' => %w[
        tako1k
        tako1k2-3b
      ],
      'サーモン' => [
        'reoysalmon'
      ],
      'Oyster38' => [
        'oyster38'
      ],
      'サムライ佃煮' => %w[
        tsukudani
        tsukuani
        tsukuani6
        tsukudani6
      ]
    }
    item_ids.map { |id| sections[section_name].include?(id) }.flatten.compact.include?(true)
  end

  def item_names
    item_names = {
      'kakiset302' => '坂越産 生むき身500g×2 + 殻付30個',
      'kakiset202' => '坂越産 生むき身500g×2 + 殻付20個',
      'kakiset301' => '坂越産 生むき身500g×1 + 殻付30個',
      'kakiset201' => '坂越産 生むき身500g×1 + 殻付20個',
      'kakiset101' => '坂越産 生むき身500g×1 + 殻付10個',
      'karatsuki100' => '坂越産 生殻付き 牡蠣100ヶ',
      'karatsuki50' => '坂越産 生殻付き 牡蠣50ヶ',
      'karatsuki40' => '坂越産 生殻付き 牡蠣40ヶ',
      'karatsuki30' => '坂越産 生殻付き 牡蠣30ヶ',
      'karatsuki20' => '坂越産 生殻付き 牡蠣20ヶ',
      'karatsuki10' => '坂越産 生殻付き 牡蠣10ヶ',
      'mukimi04' => '坂越産 生牡蠣むき身500g×4',
      'mukimi03' => '坂越産 生牡蠣むき身500g×3',
      'mukimi02' => '坂越産 生牡蠣むき身500g×2',
      'mukimi01' => '坂越産 生牡蠣むき身500g×1',
      'pkara100' => '坂越産 冷凍殻付き 牡蠣100ヶ',
      'pkara50' => '坂越産 冷凍殻付き 牡蠣50ヶ',
      'pkara40' => '坂越産 冷凍殻付き 牡蠣40ヶ',
      'pkara30' => '坂越産 冷凍殻付き 牡蠣30ヶ',
      'pkara20' => '坂越産 冷凍殻付き 牡蠣20ヶ',
      'pkara10' => '坂越産 冷凍殻付き 牡蠣10ヶ',
      'pmuki04' => '坂越産 冷凍牡蠣むき身500g×4',
      'pmuki03' => '坂越産 冷凍牡蠣むき身500g×3',
      'pmuki02' => '坂越産 冷凍牡蠣むき身500g×2',
      'pmuki01' => '坂越産 冷凍牡蠣むき身500g×1',
      'tako1k' => '兵庫県産 ボイルたこ Lサイズ (800g~1kg)',
      'tako1k2-3b' => '兵庫県産 ボイルたこ Mサイズ (2~3匹) 1kg',
      'mebi80x5' => '兵庫県産 むき干しえび 80g×5袋',
      'mebi80x3' => '兵庫県産 むき干しえび 80g×3袋',
      'hebi80x10' => '兵庫県産 殻付き干しえび 80g×10袋',
      'hebi80x5' => '兵庫県産 殻付き干しえび 80g×5袋',
      'anago600' => '兵庫県産 焼き穴子 600g入',
      'anago480' => '兵庫県産 焼き穴子 480g入',
      'anago350' => '兵庫県産 焼き穴子 350g',
      'syoukara1kg' => '坂越産 殻付き生牡蠣 1kg',
      'syoukara2kg' => '坂越産 殻付き生牡蠣 2㎏',
      'syoukara3kg' => '坂越産 殻付き生牡蠣 3㎏',
      'syoukara5kg' => '坂越産 殻付き生牡蠣 5㎏',
      'reoysalmon' => '坂越産 冷凍オイスターサーモン 400~600g',
      'oyster38' => 'Oyster38 オイスターソース',
      'tsukudani' => 'サムライオイスター佃煮×3',
      'tsukuani' => 'サムライオイスター佃煮×3',
      'tsukuani6' => 'サムライオイスター佃煮×6',
      'tsukudani6' => 'サムライオイスター佃煮×6',
      'sbt-10' => 'サムライGOLD 生殻付き 牡蠣10ヶ',
      'sbt-20' => 'サムライGOLD 生殻付き 牡蠣20ヶ',
      'sbt-30' => 'サムライGOLD 生殻付き 牡蠣30ヶ',
      'sbt-40' => 'サムライGOLD 生殻付き 牡蠣40ヶ',
      'sbt-50' => 'サムライGOLD 生殻付き 牡蠣50ヶ',
      'sbt-60' => 'サムライGOLD 生殻付き 牡蠣60ヶ',
      'sbt-70' => 'サムライGOLD 生殻付き 牡蠣70ヶ',
      'sbt-80' => 'サムライGOLD 生殻付き 牡蠣80ヶ',
      'sbt-90' => 'サムライGOLD 生殻付き 牡蠣90ヶ',
      'sbt-100' => 'サムライGOLD 生殻付き 牡蠣100ヶ'
    }
    item_ids.map { |i| item_names[i] }
  end

  def payment_type
    pay_method = billing_details['PayMethod']
    method_hash = {
      'payment_a1' => 'クレジットカード決済',
      'payment_a17' => 'PayPay残高払い',
      'payment_a6' => 'コンビニ (セブン-イレブン）',
      'payment_a7' => 'コンビニ（ファミリーマート、ローソン、その他）',
      'payment_a8' => 'モバイルSuica',
      'payment_a9' => 'ドコモ ケータイ払い',
      'payment_a10' => 'auかんたん決済',
      'payment_a11' => 'ソフトバンクまとめて支払い',
      'payment_b1' => '銀行振込',
      'payment_d1' => '商品代引'
    }
    method_hash.include?(pay_method) ? method_hash[pay_method] : pay_method
  end

  def shipping_temperatures
    temperature_setting = {
      'kakiset302' => '2',
      'kakiset202' => '2',
      'kakiset301' => '2',
      'kakiset201' => '2',
      'kakiset101' => '2',
      'karatsuki100' => '2',
      'karatsuki50' => '2',
      'karatsuki40' => '2',
      'karatsuki30' => '2',
      'karatsuki20' => '2',
      'karatsuki10' => '2',
      'mukimi04' => '2',
      'mukimi03' => '2',
      'mukimi02' => '2',
      'mukimi01' => '2',
      'pkara100' => '1',
      'pkara50' => '1',
      'pkara40' => '1',
      'pkara30' => '1',
      'pkara20' => '1',
      'pkara10' => '1',
      'pmuki04' => '1',
      'pmuki03' => '1',
      'pmuki02' => '1',
      'pmuki01' => '1',
      'tako1k' => '2',
      'tako1k2-3b' => '2',
      'mebi80x5' => '2',
      'mebi80x3' => '2',
      'hebi80x10' => '2',
      'hebi80x5' => '2',
      'anago600' => '2',
      'anago480' => '2',
      'anago350' => '2',
      'reoysalmon' => '1',
      'oyster38' => '2',
      'tsukudani' => '2',
      'tsukuani' => '2',
      'tsukuani6' => '2',
      'tsukudani6' => '2',
      'sbt-10' => '2',
      'sbt-20' => '2',
      'sbt-30' => '2',
      'sbt-40' => '2',
      'sbt-50' => '2',
      'sbt-60' => '2',
      'sbt-70' => '2',
      'sbt-80' => '2',
      'sbt-90' => '2',
      'sbt-100' => '2'
    }
    item_ids.map { |i| temperature_setting[i] }.uniq
  end

  def yamato_header
    %w[送り状種類 クール区分 出荷予定日 お届け予定日 配達時間帯 お届け先電話番号 お届け先電話番号枝番 お届け先郵便番号 お届け先住所 お届け先アパートマンション名 お届け先会社・部門１ お届け先会社・部門２ お届け先名
       お届け先名(ｶﾅ) 敬称 ご依頼主電話番号 ご依頼主郵便番号 ご依頼主住所 ご依頼主アパートマンション ご依頼主名 ご依頼主名(ｶﾅ) 品名コード１ 品名１ 品名コード２ 品名２ 荷扱い１ 荷扱い２ 記事 請求先顧客コード 運賃管理番号 コレクト代金引換額（税込）]
  end

  def yamato_shipping_format
    # https://linuxtut.com/a-story-about-converting-character-codes-from-utf-8-to-shift-jis-in-ruby-c1ff7/
    def sjisable(str)
      # Replace the characters on the conversion table with the characters below
      from_chr = "\u{301C 2212 00A2 00A3 00AC 2013 2014 2016 203E 00A0 00F8 203A}"
      to_chr   = "\u{FF5E FF0D FFE0 FFE1 FFE2 FF0D 2015 2225 FFE3 0020 03A6 3009}"
      str.to_s.tr!(from_chr, to_chr)
      # Illegal characters leaked from the conversion table?Convert to UTF8 and then back to UTF8 to prevent future exceptions
      str.to_s.encode('Windows-31J', 'UTF-8', invalid: :replace, undef: :replace).encode('UTF-8', 'Windows-31J')
    end

    require 'moji'
    [ # 送り状種類
      shipping_type,
      # クール区分
      shipping_temperatures.first,
      # 出荷予定日
      (ship_date || Time.zone.today).strftime('%Y/%m/%d'),
      # お届け予定日
      shipping_arrival_date.strftime('%Y/%m/%d'),
      # 配達時間帯
      yamato_arrival_time,
      # お届け先電話番号
      shipping_phone,
      # お届け先電話番号枝番
      '',
      # お届け先郵便番号
      shipping_details['ShipZipCode'],
      # お届け先住所
      shipping_details['ShipPrefecture'] + shipping_details['ShipCity'] + shipping_details['ShipAddress1'],
      # お届け先アパートマンション名
      '',
      # お届け先会社・部門１
      shipping_details['ShipAddress2'],
      # お届け先会社・部門２
      '',
      # お届け先名
      shipping_name,
      # お届け先名(ｶﾅ)
      Moji.zen_to_han(shipping_name_kana),
      # 敬称
      '様',
      # ご依頼主電話番号
      yamato_fix_billing_phone,
      # ご依頼主郵便番号
      yamato_fix_billing_zip,
      # ご依頼主住所
      yamato_fix_billing_address,
      # ご依頼主アパートマンション
      yamato_fix_billing_address2,
      # ご依頼主名
      yamato_fix_billing_name,
      # ご依頼主名(ｶﾅ)
      yamato_fix_billing_name_kana,
      # 品名コード１
      '', # removed for now at request item_details["ProductId"],
      # 品名１
      item_names.each_with_index.map { |item, i| "#{item}#{print_quantity(i)}" }.join(', '),
      # 品名コード２
      '',
      # 品名２
      '',
      # 荷扱い１
      'ナマモノ',
      # 荷扱い２
      '天地無用',
      # 記事
      '',
      # 請求先顧客コード
      '079143655602',
      # 運賃管理番号
      '01',
      # コレクト代金引換額（税込）
      total_price
    ].map { |c| c.nil? ? '' : sjisable(c) }
  end
end
