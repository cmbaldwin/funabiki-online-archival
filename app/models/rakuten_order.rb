class RakutenOrder < ApplicationRecord
  belongs_to :stat, optional: true

  # Without a status the default scope will throw an error on every page using this ActiveRecord model
  validates :status, presence: true
  validates :order_id, presence: true
  validates :order_id, uniqueness: true # Needs index

  serialize :data

  # Return orders that includes pacakges that should be shipped today
  default_scope { where.not(status: [800, 900]) }
  scope :new_orders, -> { where(status: 100) }
  # Searchs array of ship dates for date string
  scope :ship_today, -> { where("ship_dates @> '{#{Time.zone.today}}'") }
  # Searchs array of ship dates for date string
  scope :with_date, ->(date) { where("ship_dates @> '{#{date}}'") }
  # Searchs array of ship dates for date string
  scope :with_dates, ->(dates) { where('ship_dates && array[?]', dates.map { |d| d.to_s }) }
  # Searches by order time (may exclude some orders on the season edge)
  scope :this_season, -> { where(order_time: ShopsHelper.this_season_start..ShopsHelper.this_season_end) }
  scope :prior_season, lambda {
                         where(order_time: ShopsHelper.prior_season_start..ShopsHelper.prior_season_end)
                       }

  def cancelled
    status == 800 || status == 900
  end

  def encoded_shop_code
    order_id.scan(/\d*(?=-)/).first
  end

  def encoded_order_date
    order_id.scan(/(?<=-)\d*/).first
  end

  def encoded_order_id
    order_id.scan(/(?<=-)\d*/).second
  end

  def print_status
    # Status
    # 100: 注文確認待ち
    # 200: 楽天処理中
    # 300: 発送待ち
    # 400: 変更確定待ち
    # 500: 発送済
    # 600: 支払手続き中
    # 700: 支払手続き済
    # 800: キャンセル確定待ち
    # 900: キャンセル確定
    { 100 => '注文確認待ち',
      200 => '楽天処理中',
      300 => '発送待ち',
      400 => '変更確定待ち',
      500 => '発送済',
      600 => '支払手続き中',
      700 => '支払手続き済',
      800 => 'キャンセル確定待ち',
      900 => 'キャンセル確定' }[status]
  end

  def packages
    data['PackageModelList']
  end

  def ship_date_string(package)
    if shipping(package).length == 1
      shipping(package).first['shippingDate']
    elsif shipping(package).length > 1
      if shipping(package).first['shippingDate'].nil?
        shipping(package).second['shippingDate']
      else
        shipping(package).first['shippingDate']
      end
    end
  end

  def ship_date(package)
    Date.parse(ship_date_string(package))
  end

  def shipping_date
    # always return a date in date formate
    ship_dates.empty? ? order_time : ship_dates.first
  end

  def sender
    data['OrdererModel']
  end

  def sender_family_name
    sender['familyName']
  end

  def print_sender_name
    "#{sender['familyName']} #{sender['firstName']}"
  end

  def sender_recipient(package)
    (print_sender_name == print_recipient_name(package))
  end

  def recipient(package)
    package['SenderModel']
  end

  def print_recipient_name(package)
    rd = recipient(package)
    "#{rd['familyName']} #{rd['firstName']}"
  end

  def items(package)
    package['ItemModelList']
  end

  def shipping(package)
    package['ShippingModelList']
  end

  def arrival_time
    # 0: なし
    # 1: 午前
    # 2: 午後
    # 9: その他
    # h1h2: h1時-h2時 (h1は7～24まで任意で数値指定可能。h2は07～24まで任意で数値指定可能)
    data['shippingTerm']
  end

  def print_arrival_time
    convert = {
      0 => '',
      1 => '午前',
      2 => '午後',
      9 => 'その他'

    }
    if convert.include?(arrival_time)
      convert[arrival_time]
    elsif arrival_time.to_s.length == 4
      arrival_time.to_s.insert(2, '時~').insert(6, '時')
    end
  end

  def earliest_arrival(prefecture, city, errors)
    # {"prefecture" => { "city" => [days_to_arrival_integer, time_on_that_day_integer] } }
    # def add_hours_enum(integer)
    #   {
    #     0 => 12.hours,
    #     1 => 16.hours,
    #     2 => 18.hours}[integer]
    # end
    # def add_hours_string(string)
    #   {
    #     '午前中' => 12.hours,
    #     '14:00-16:00' => 16.hours,
    #     '16:00-18:00' => 18.hours,
    #     '18:00-20:00' => 20.hours,
    #     '19:00-21:00' => 21.hours
    #   }[string]
    # end
    arrival_hash = {
      # 北海道
      '北海道' => {
        base: [2, 0],
        '奥尻郡' => [2, 2]
      },
      # 北南北
      '青森県' => { base: [2, 0] },
      '岩手県' => { base: [2, 0] },
      '秋田県' => { base: [2, 0] },
      # 南東北
      '宮城県' => { base: [1, 1] },
      '山形県' => {
        base: [1, 2],
        '上山市' => [1, 1],
        '寒河江市' => [1, 1],
        '天童市' => [1, 1],
        '東根市' => [1, 1],
        '村山市' => [1, 1],
        '山形市' => [1, 1]
      },
      '福島県' => { base: [1, 2],
                 '会津若松市' => [1, 1],
                 '安達郡' => [1, 1],
                 '大沼郡' => [1, 1],
                 '河沼郡' => [1, 1],
                 '喜多方市' => [1, 1],
                 '郡山市' => [1, 1],
                 '伊達郡' => [1, 1],
                 '伊達市' => [1, 1],
                 '二本松市' => [1, 1],
                 '福島市' => [1, 1],
                 '本宮市' => [1, 1],
                 '耶麻市' => [1, 1] },
      # 関東
      '茨城県' => { base: [1, 1] },
      '栃木県' => { base: [1, 1] },
      '群馬県' => {
        base: [1, 1],
        '吾妻郡' => [1, 2]
      },
      '埼玉県' => { base: [1, 0] },
      '千葉県' => { base: [1, 0] },
      '神奈川県' => { base: [1, 0] },
      '東京都' => { base: [1, 0] },
      '山梨県' => { base: [1, 0] },
      # 信越
      '新潟県' => { base: [1, 1] },
      '長野県' => { base: [1, 0] },
      # 北陸
      '富山県' => { base: [1, 0] },
      '石川県' => { base: [1, 0] },
      '福井県' => { base: [1, 0] },
      # 中部
      '岐阜県' => { base: [1, 0] },
      '静岡県' => { base: [1, 0] },
      '愛知県' => { base: [1, 0] },
      '三重県' => { base: [1, 0] },
      # 関西
      '滋賀県' => { base: [1, 0] },
      '京都府' => { base: [1, 0] },
      '大阪府' => { base: [1, 0] },
      '兵庫県' => { base: [1, 0] },
      '奈良県' => { base: [1, 0] },
      '和歌山県' => { base: [1, 0] },
      # 中国
      '鳥取県' => { base: [1, 0] },
      '島根県' => {
        base: [1, 0],
        '隠岐郡' => [1, 1]
      },
      '岡山県' => { base: [1, 0] },
      '広島県' => { base: [1, 0] },
      '山口県' => { base: [1, 0] },
      # 四国
      '徳島県' => { base: [1, 0] },
      '香川県' => { base: [1, 0] },
      '愛媛県' => { base: [1, 0] },
      '高知県' => { base: [1, 0] },
      # 九州
      '福岡県' => { base: [1, 0] },
      '佐賀県' => { base: [1, 1] },
      '長崎県' => {
        base: [1, 1],
        '小値賀島' => [2, 2],
        '五島市' => [2, 2],
        '対馬市' => [2, 0],
        '南松浦郡' => [2, 2]
      },
      '熊本県' => {
        base: [1, 1],
        '天草郡' => [1, 2],
        '天草市' => [1, 2]
      },
      '大分県' => {
        base: [1, 1],
        '中津市' => [1, 0]
      },
      '宮崎県' => { base: [1, 1] },
      '鹿児島県' => {
        base: [1, 1],
        '奄美市' => [2, 0],
        '大島郡' => [2, 1],
        '大島郡龍郷町' => [2, 0],
        '熊毛郡南種子町' => [2, 2],
        '熊毛郡' => [2, 2],
        '熊西之表市' => [2, 2]
      },
      # 沖縄県
      '沖縄県' => {
        base: [2, 0],
        '石垣市' => [2, 2],
        '島尻郡' => [2, 1],
        '宮古島市' => [2, 2]
      }

    }
    if arrival_hash.keys.include?(prefecture)
      if arrival_hash[prefecture].keys.include?(city)
        arrival_hash[prefecture][city]
      else
        arrival_hash[prefecture][:base]
      end
    else
      errors[:earliest_arrival] = ['Error: no pref or city keys found', [prefecture, city]]
      [1, 0]
    end
  end

  def order_addresses
    data['PackageModelList'].map do |pkg|
      { zip: pkg['SenderModel'].values[0..1].join,
        prefecture: pkg['SenderModel'].values[2],
        city: pkg['SenderModel'].values[3],
        address: pkg['SenderModel'].values[4],
        last_name: pkg['SenderModel'].values[5],
        first_name: pkg['SenderModel'].values[6],
        katakana_last_name: pkg['SenderModel'].values[7],
        katakana_first_name: pkg['SenderModel'].values[8],
        phone: pkg['SenderModel'].values[9..12].join,
        item_id: pkg['ItemModelList'].map { |item| item['manageNumber'] } }
    end
  end

  def settlement_method
    data['SettlementModel']['settlementMethod']
  end

  def daibiki
    settlement_method == '代金引換'
  end

  def charged
    data['requestPrice']
  end

  def total_price
    data['totalPrice']
  end

  def remarks
    data['remarks'].nil? ? '' : data['remarks']
  end

  def remark_datetime
    remarks[/\d.*/]
  end

  def remark_message
    remarks.remove('[配送日時指定:]', /\d.*/, '午前中', '[メッセージ添付希望・他ご意見、ご要望がありましたらこちらまで:]').strip
  end

  def memo
    data['memo'].nil? ? '' : data['memo']
  end

  def wrapping
    [data['WrappingModel1'], data['WrappingModel2']].compact
  end

  def shipping_numbers
    packages.map { |pkg| pkg['ShippingModelList'].map { |item| item['shippingNumber'] } }.flatten.compact
  end

  def knife_count
    wrapping.map { |wrap| (1 if wrap['name'].include?('ナイフ')) if wrap.is_a?(Hash) }.compact.sum
  end

  def tsukudani_set
    wrapping.map { |wrap| (1 if wrap['name'].include?('佃煮')) if wrap.is_a?(Hash) }.compact.sum
  end

  def tsukudani_count
    tsukudani_set
  end

  def sauce_set
    wrapping.map do |wrap|
      if wrap.is_a?(Hash)
        (1 if wrap['name'].include?('Oyster38'))
      end
    end.compact.sum
  end

  def sauce_count
    sauce_set
  end

  def noshi
    msg = packages.map { |pkg| pkg['noshi'] }.compact
    msg << data['giftCheckFlag'] unless data['giftCheckFlag'].zero?
    msg.reject { |item| item == "のし無し" }
  end

  def receipt
    if remarks.include?('領収書をメール')
      '領収書(メール)'
    elsif remarks.include?('領収書を同梱')
      '領収書(同梱)'
    elsif remarks.include?('領収') || memo.include?('領収')
      '領収書'
    else
      ''
    end
  end

  def has_noshi_receipt
    !noshi.empty? || !receipt.empty?
  end

  def item_id_to_yamato_box_size(item_id)
    {
      '10000018' => 80, # m1
      '10000001' => 80, # m2
      '10000035' => 80, # tm2
      '10000002' => 100, # m3
      '10000003' => 100, # m4
      '10000027' => 80, # p1
      '10000030' => 80, # p2
      '10000028' => 80, # p3
      '10000029' => 100, # p4
      '10000015' => 60, # k10
      '10000004' => 80, # k20
      '10000005' => 80, # k30
      '10000025' => 80, # k40
      '10000006' => 100, # k50
      '10000040' => 100, # k100
      '10000031' => 60, # pk10
      '10000037' => 80, # pk20
      '10000038' => 80, # pk30
      '10000039' => 80, # pk40
      '10000041' => 100, # pk50
      '10000042' => 100, # pk100
      '10000007' => 80, # s110
      '10000008' => 80, # s120
      '10000022' => 100, # s130
      '10000009' => 100, # s220
      '10000023' => 100, # s230
      'boiltako800-1k' => 80, # tako
      'boiltako-2-3biki' => 80, # tako
      '10000012' => 60, # a350
      '10000013' => 60, # a480
      '10000014' => 60, # a560
      '10000017' => 60, # em1
      '10000016' => 60, # em2
      '10000010' => 60, # kem1
      '10000011' => 60, # kem2
      'barakaki_1k' => 60, # bkar1
      'barakaki_2k' => 80, # bkar2
      'barakaki_3k' => 80, # bkar3
      'barakaki_5k' => 80, # bkar5
      'reito_oyster_salmon' => 80, # salmon
      'oyster38' => 60, # oyster38
      'tsukudani' => 60, # tsukudani
      'tsukudani6' => 80, # Tsukud6
      'sbt-10' => 60, # sbt10
      'sbt-20' => 80, # sbt20
      'sbt-30' => 80, # sbt30
      'sbt-40' => 80, # sbt40
      'sbt-50' => 100, # sbt50
      'sbt-60' => 100, # sbt60
      'sbt-70' => 100, # sbt70
      'sbt-80' => 100, # sbt80
      'sbt-90' => 100, # sbt90
      'sbt-100' => 100 # sbt100
    }[item_id]
  end

  def rakuten_rate
    0.25
  end

  def profit_estimate
    (total_price - expenses_estimate - raw_costs - shipping_estimate).to_i
  end

  def expenses_estimate
    expenses = item_ids_counts.map { |item| item_expenses(item[0]) * item[1] }.sum
    charges = total_price * rakuten_rate
    (expenses + charges)
  end

  def shipping_estimate
    # add diabiki here
    basic_estimate = order_addresses.map do |pkg|
      pkg[:item_id].map do |id|
        calculate_shipping(pkg[:prefecture], item_id_to_yamato_box_size(id))
      end
    end.flatten.sum
    daibiki ? (basic_estimate + (shipping_numbers.count * 330)) : basic_estimate
  end

  def item_expenses(_item_id)
    400 # Just using an average expense for the time being
  end

  def item_counts(item_id)
    { # [nama_muki, nama_kara, shell_cards, p_muki, p_kara, anago, mebi, kebi, tako, barakara, salmon, sauce, tsukudani, triploid ]
      '10000018' => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m1
      '10000001' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m2
      '10000035' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # tm2
      '10000001campaign' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # cm2
      '10000002' => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m3
      '10000003' => [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m4
      '10000027' => [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p1
      '10000030' => [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p2
      '10000028' => [0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p3
      '10000029' => [0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p4
      '10000026' => [0, 10, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k10
      '10000015' => [0, 10, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k10
      '10000004' => [0, 20, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k20
      '10000005' => [0, 30, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k30
      '10000025' => [0, 40, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k40
      '10000006' => [0, 50, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k50
      '10000040' => [0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k100
      '10000031' => [0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk10
      '10000037' => [0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk20
      '10000038' => [0, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk30
      '10000039' => [0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk40
      '10000041' => [0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk50
      '10000042' => [0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk100
      '10000007' => [1, 10, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s110
      '10000008' => [1, 20, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s120
      '10000022' => [1, 30, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s130
      '10000009' => [2, 20, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s220
      '10000023' => [2, 30, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s230
      '10000012' => [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], # a350
      '10000013' => [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], # a480
      '10000014' => [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], # a560
      '10000017' => [0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0], # em1
      '10000016' => [0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0], # em2
      '10000010' => [0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0], # kem1
      '10000011' => [0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0], # kem2
      'barakaki_1k' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], # bkar1
      'barakaki_2k' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0], # bkar2
      'barakaki_3k' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0], # bkar3
      'barakaki_5k' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0], # bkar5
      'boiltako800-1k' => [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0], # Ltako
      'boiltako-2-3biki' => [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0], # Mtako
      'reito_oyster_salmon' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], # OSalmon
      'oyster38' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], # oyster38
      'tsukudani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0], # tsukudani3
      'tsukudani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0], # Tsukud6
      'sbt-10' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10], # sbt10
      'sbt-20' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20], # sbt20
      'sbt-30' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30], # sbt30
      'sbt-40' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40], # sbt40
      'sbt-50' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50], # sbt50
      'sbt-60' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60], # sbt60
      'sbt-70' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70], # sbt70
      'sbt-80' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80], # sbt80
      'sbt-90' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90], # sbt90
      'sbt-100' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100] # sbt100
    }[item_id] || [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  end

  def sku_id(item)
    variant = item.dig("SkuModelList", 0, "variantId") # in case older orders don't have skuModelList
    variant = nil if variant == 'normal-inventory' # normal-inventory is the default sku variant id when no variants are availiable
    variant || item["manageNumber"]
  end

  def item_ids_counts(search_date = nil)
    packages.map do |pkg|
      next unless search_date.nil? ? true : (ship_date(pkg) == search_date)

      pkg['ItemModelList'].map do |item|
        [sku_id(item),
         item['units']]
      end
    end.flatten(1).compact
  end

  def package_item_sections(package)
    sectioned_items = {}
    sections = {
      mukimi: [
        '10000018', # m1
        '10000001', # m2
        '10000035', # tm2
        '10000002', # m3
        '10000003' # m4
      ],
      shells: [
        '10000026', # k10 old, deleted
        '10000015', # k10
        '10000004', # k20
        '10000005', # k30
        '10000025', # k40
        '10000006', # k50
        '10000040', # k100
        'barakaki_1k', # bkar1
        'barakaki_2k', # bkar2
        'barakaki_3k', # bkar3
        'barakaki_5k' # bkar5
      ],
      triploid: [
        'sbt-10', # sbt10
        'sbt-20', # sbt20
        'sbt-30', # sbt30
        'sbt-40', # sbt40
        'sbt-50', # sbt50
        'sbt-60', # sbt60
        'sbt-70', # sbt70
        'sbt-80', # sbt80
        'sbt-90', # sbt90
        'sbt-100' # sbt100
      ],
      sets: [
        '10000007', # s110
        '10000008', # s120
        '10000022', # s130
        '10000009', # s220
        '10000023' # s230
      ],
      other: [
        '10000027', # p1
        '10000030', # p2
        '10000028', # p3
        '10000029', # p4
        '10000031', # pk10
        '10000037', # pk20
        '10000038', # pk30
        '10000039', # pk40
        '10000041', # pk50
        '10000042', # pk100
        '10000012', # a350
        '10000013', # a480
        '10000014', # a560
        '10000017', # em1
        '10000016', # em2
        '10000010', # kem1
        '10000011', # kem2
        'boiltako800-1k', # tako-lg
        'boiltako-2-3biki', # tako-sm
        'reito_oyster_salmon', # salmon
        'oyster38', # oyster38
        'tsukudani', # tsukudani3
        'tsukudani6' # tsukudani6
      ]
    }
    items(package).map { |item| [item['manageNumber'], item['units']] }.each do |item_id, quantity|
      sections.each do |section_header, id_array|
        sectioned_items[section_header] = [] unless sectioned_items[section_header].is_a?(Array)
        sectioned_items[section_header] << [item_id, quantity] if id_array.include?(item_id)
      end
    end
    sectioned_items
  end

  def type_counts(search_date = nil)
    item_ids_counts(search_date).each_with_object({}) do |(id, quantity), count|
      quantity.times do
        EcProduct.with_reference_id(id).each do |product|
          type_id = product.ec_product_type_id
          next unless type_id

          count[type_id] ||= 0
          count[type_id] += product.quantity || 1
        end
      end
    end
  end

  def counts(search_date = nil)
    item_ids_counts(search_date).each_with_object({}) do |(id, quantity), count|
      quantity.times do
        count.nil? ? (count = item_counts(id.to_s)) : (item_counts(id.to_s).each_with_index { |v, i| count[i] += v })
      end
    end
    count
  end

  def item_count
    counts.sum
  end

  def mukimi_sales_estimate
    if mukimi_count > 0
      relevant_items = packages.map do |pkg|
        package_item_sections(pkg).fetch_values(:mukimi, :sets).reject(&:empty?).flatten(1)
      end.flatten(1)
      shell_sales_estimate = # 100 yen per shell
        relevant_items.map do |arr|
          shells = item_counts(arr[0])[1]
          shells.zero? ? 0 : (shells * arr[1] * 100)
        end.sum
      total_price - shell_sales_estimate - expenses_estimate - shipping_estimate
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
      (mukimi_sales_estimate - (raw_oyster_costs(shipping_date).values[0] + (60 * mukimi_count))).to_i
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

  def shell_cards
    @search_date ? counts(@search_date)[2] : counts[2]
  end

  def item_raw_usage(item_id)
    { # [nama_muki, nama_kara, p_muki, p_kara, anago, mebi, kebi, tako, barakara, salmon, sauce, tsukudani, triploid ]
      '10000018' => [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m1
      '10000001' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m2
      '10000035' => [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # tm2
      '10000002' => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m3
      '10000003' => [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # m4
      '10000027' => [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p1
      '10000030' => [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p2
      '10000028' => [0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p3
      '10000029' => [0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # p4
      '10000026' => [0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k10
      '10000015' => [0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k10
      '10000004' => [0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k20
      '10000005' => [0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k30
      '10000025' => [0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k40
      '10000006' => [0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k50
      '10000040' => [0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # k100
      '10000031' => [0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk10
      '10000037' => [0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk20
      '10000038' => [0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk30
      '10000039' => [0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk40
      '10000041' => [0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk50
      '10000042' => [0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0], # pk100
      '10000007' => [1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s110
      '10000008' => [1, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s120
      '10000022' => [1, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s130
      '10000009' => [2, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s220
      '10000023' => [2, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # s230
      '10000012' => [0, 0, 0, 0, 0.350, 0, 0, 0, 0, 0, 0, 0, 0], # a350
      '10000013' => [0, 0, 0, 0, 0.480, 0, 0, 0, 0, 0, 0, 0, 0], # a480
      '10000014' => [0, 0, 0, 0, 0.560, 0, 0, 0, 0, 0, 0, 0, 0], # a560
      '10000017' => [0, 0, 0, 0, 0, 0.400, 0, 0, 0, 0, 0, 0, 0], # em1
      '10000016' => [0, 0, 0, 0, 0, 0.240, 0, 0, 0, 0, 0, 0, 0], # em2
      '10000010' => [0, 0, 0, 0, 0, 0, 0.320, 0, 0, 0, 0, 0, 0], # kem1
      '10000011' => [0, 0, 0, 0, 0, 0, 0.640, 0, 0, 0, 0, 0, 0], # kem2
      'barakaki_1k' => [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], # bkar1
      'barakaki_2k' => [0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0], # bkar2
      'barakaki_3k' => [0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0], # bkar3
      'barakaki_5k' => [0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0], # bkar5
      'boiltako800-1k' => [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0], # tako
      'boiltako-2-3biki' => [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0], # tako
      'reito_oyster_salmon' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0], # salmon
      'oyster38' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], # oyster38
      'tsukudani' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0], # tsukudani3
      'tsukudani6' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0], # Tsukud6
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
    }[item_id] || 0
  end

  def raw_costs
    cost = 0
    costs = raw_oyster_costs(shipping_date).values
    order_addresses.map { |pkg| pkg[:item_id].flatten }.flatten.compact.each do |item_id|
      item_raw_usage(item_id.to_s).each_with_index do |count, i|
        cost += (count * costs[i]) unless costs[i].nil?
      end
    end
    cost
  end

  def url
    "https://order-rp.rms.rakuten.co.jp/order-rb/individual-order-detail-sc/init?orderNumber=#{order_id}"
  end

  def section(section_name)
    sections = {
      '水切り' => [
        '10000018', # m1
        '10000001', # m2
        '10000035', # tm2
        '10000002', # m3
        '10000003' # m4
      ],
      'セル' => [
        '10000026', # k10
        '10000015', # k10
        '10000004', # k20
        '10000005', # k30
        '10000025', # k40
        '10000006', # k50
        '10000040' # k100
      ],
      '三倍体' => [
        'sbt-10', # sbt10
        'sbt-20', # sbt20
        'sbt-30', # sbt30
        'sbt-40', # sbt40
        'sbt-50', # sbt50
        'sbt-60', # sbt60
        'sbt-70', # sbt70
        'sbt-80', # sbt80
        'sbt-90', # sbt90
        'sbt-100' # sbt100
      ],
      '小セル' => [
        'barakaki_1k', # bkar1
        'barakaki_2k', # bkar2
        'barakaki_3k', # bkar3
        'barakaki_5k' # bkar5
      ],
      'セット' => [
        '10000007', # s110
        '10000008', # s120
        '10000022', # s130
        '10000009', # s220
        '10000023' # s230
      ],
      'デカプリ' => [
        '10000027', # p1
        '10000030', # p2
        '10000028', # p3
        '10000029'
      ],
      '冷凍セル' => [
        '10000031', # pk10
        '10000037', # pk20
        '10000038', # pk30
        '10000039', # pk40
        '10000041', # pk50
        '10000042' # pk100
      ],
      '焼き穴子' => [
        '10000012', # a350
        '10000013', # a480
        '10000014' # a560
      ],
      '干し海老' => [
        '10000017', # em1
        '10000016', # em2
        '10000010', # kem1
        '10000011' # kem2
      ],
      'タコ' => [
        'boiltako800-1k',
        'boiltako-2-3biki'
      ],
      'サーモン' => [
        'reito_oyster_salmon'
      ],
      'Oyster38' => [
        'oyster38'
      ],
      'サムライ佃煮' => %w[
        tsukudani
        tsukudani6
      ]
    }

    item_ids_counts.map do |id_count_array|
      sections[section_name].include?(id_count_array[0])
    end.flatten.compact.include?(true)
  end
end
