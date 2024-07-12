# This is the old Rakuten API, which has been depreciated. It is being kept here for reference.

class OldRakutenAPI
  include HTTParty
  require 'json'
  # There is one required variable
  # Base64.encode64(x + ":"  + y) then remove the \n (there should be two of these linebreaks), so:
  # Base64.encode64("#{SERVICE_SECRET}:#{LICENSE_KEY}").gsub("\n", '')
  # authorization = 'ESA ' + ENV['RAKUTEN_API']
  def initialize
    # We use the first user as a default because our first user is an admin
    authorization = 'ESA ' + ENV.fetch('RAKUTEN_API', nil)
    @auth_header = {
      "Authorization" => authorization,
      "Content-Type" => "application/json; charset=utf-8"
    }
  end

  def do_search(start_date_time, end_date_time, page = 1)
    HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/searchOrder/",
      :headers => @auth_header,
      :body => {
        "dateType" => 4,
        "startDatetime" => start_date_time,
        "endDatetime" => end_date_time,
        "PaginationRequestModel" => {
          "requestRecordsAmount" => 1000,
          "requestPage" => page,
          "SortModelList" => [{
            "sortColumn" => 1,
            "sortDirection" => 1 }]
      }}.to_json)
  end

  def refresh(date = Time.zone.today)
    start_date_time = date.to_time.strftime('%Y-%m-%dT%H:%M:%S') + '+0900'
    end_date_time = (date.to_time + 23.hours + 59.minutes + 59.seconds).strftime('%Y-%m-%dT%H:%M:%S') + '+0900'
    existing_orders = RakutenOrder.with_date(date).map{|o| o.order_id}

    begin
      response = do_search(start_date_time, end_date_time).parsed_response
      id_array = response["orderNumberList"]
      id_array << existing_orders
      id_array ? get_details_by_ids(id_array.flatten.uniq).flatten : "Unexepected response: #{response}"
    rescue => error
      ap error
      ap error.backtrace
    end

  end

  def big_refresh
    start_date_time = (Time.zone.today - 1.month).to_time.strftime('%Y-%m-%dT%H:%M:%S') + '+0900'
    end_date_time = (Time.zone.today + 1.month).strftime('%Y-%m-%dT%H:%M:%S') + '+0900'

    begin
      response = do_search(start_date_time, end_date_time).parsed_response
      pages = response["PaginationResponseModel"]["totalPages"]
      id_array = response["orderNumberList"]
      if pages > 1
        # do it again that many pages
        left_to_do = pages.to_i - 1
        left_to_do.times do |page|
          response = do_search(start_date_time, end_date_time, page).parsed_response
          id_array << response["orderNumberList"]
        end
      end
      id_array ? get_details_by_ids(id_array.flatten).flatten : "Unexepected response: #{response}"
    rescue => error
      ap error
      ap error.backtrace
    end
  end

  # This is a tool for converting from the old RManifest (collective) format to Rakuten Orders (individual) format
  def rmanifest_to_rakuten_orders
    RManifest.all.each do |manifest|
      orders = manifest.new_orders_hash
      orders.each do |order|
        begin
          details = order[:raw_data]
          rakuten_order = RakutenOrder.find_by(order_id: details["orderNumber"])
          rakuten_order = RakutenOrder.new(order_id: details["orderNumber"]) if rakuten_order.nil?
          rakuten_order.assign_attributes({
              order_time: DateTime.parse(details["orderDatetime"]),
              arrival_date: Date.parse(details["deliveryDate"]),
              ship_dates: details["PackageModelList"].map{|pkg| pkg["ShippingModelList"].map{|ship| Date.parse(ship["shippingDate"]) unless ship["shippingDate"].nil? } }.flatten.compact.uniq,
              status: details["orderProgress"],
              data: details
            })
          rakuten_order.save
        rescue => error
          ap error
          ap error.backtrace
          ap order
        end
      end
    end
  end

  def get_ids_by_sales_date(sales_date = Time.zone.today.strftime("%Y年%m月%d日"))
    sales_date = sales_date
    start_date_time = DateTime.strptime(sales_date, "%Y年%m月%d日").strftime('%Y-%m-%dT%H:%M:%S') + '+0900'
    end_date_time = (DateTime.strptime(sales_date, "%Y年%m月%d日") + 23.hours + 59.minutes + 59.seconds).strftime('%Y-%m-%dT%H:%M:%S') + '+0900'

    get_orders_list = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/searchOrder/",
      :headers => @auth_header,
      :body => {
        "dateType" => 4,
        "startDatetime" => start_date_time,
        "endDatetime" => end_date_time,
        "PaginationRequestModel" => {
          "requestRecordsAmount" => 1000,
          "requestPage" => 1,
          "SortModelList" => [{
            "sortColumn" => 1,
            "sortDirection" => 1 }]
      }}.to_json)
    get_orders_list.parsed_response
  end

  #get one week of new orders in the "before confirmation" status ("100")
  def get_unprocessed_shinki
    date = Time.zone.today
    start_date_time = (date - 7.days).strftime('%Y-%m-%dT%H:%M:%S') + '+0900'
    end_date_time = (date + 23.hours + 59.minutes + 59.seconds).strftime('%Y-%m-%dT%H:%M:%S') + '+0900'

    get_orders_list = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/searchOrder/",
      :headers => @auth_header,
      :body => {
        "orderProgressList" => [100],
        "dateType" => 1,
        "startDatetime" => start_date_time,
        "endDatetime" => end_date_time,
        "PaginationRequestModel" => {
          "requestRecordsAmount" => 1000,
          "requestPage" => 1,
          "SortModelList" => [{
            "sortColumn" => 1,
            "sortDirection" => 1 }]
      }}.to_json).parsed_response
    number_list = get_orders_list["orderNumberList"]
    number_list ? number_list : (ap get_orders_list)
  end

  #get one week of new orders
  def get_shinki_without_shipdate_ids(finish_date = Time.zone.today, period_back = 7.days)
    start_date_time = (finish_date - period_back).strftime('%Y-%m-%dT%H:%M:%S') + '+0900'
    end_date_time = (finish_date + 23.hours + 59.minutes + 59.seconds).strftime('%Y-%m-%dT%H:%M:%S') + '+0900'

    get_orders_list = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/searchOrder/",
      :headers => @auth_header,
      :body => {
        # only incomplete orders unless + 500,600,700,800,900
        "orderProgressList" => [100,200,300,400],
        "dateType" => 1,
        "startDatetime" => start_date_time,
        "endDatetime" => end_date_time,
        "shippingDateBlankFlag" => 1,
        "PaginationRequestModel" => {
          "requestRecordsAmount" => 1000,
          "requestPage" => 1,
          "SortModelList" => [{
            "sortColumn" => 1,
            "sortDirection" => 1 }]
      }}.to_json)
    get_orders_list["orderNumberList"]
  end

  def get_details_by_ids(id_array)
    if id_array.is_a?(Array)
      unless id_array.empty?
        if id_array.length > 100
          orders_list_by_100 = id_array.each_slice(100).to_a
          order_details = Array.new
          messages = Array.new
          orders_list_by_100.each do |sub_list|
            get_order_details = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/getOrder/",
              :headers => @auth_header,
              :body => {"orderNumberList" => sub_list,"version" => 3}.to_json)
            order_details << get_order_details["OrderModelList"]
            messages << get_order_details["MessageModelList"]
            ap messages if (!messages.empty? && messages.to_s.include?("ERROR"))
          end
        else
          get_order_details = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/getOrder/",
            :headers => @auth_header,
            :body => {"orderNumberList" => id_array,"version" => 3}.to_json)
          order_details = get_order_details["OrderModelList"]
          messages = get_order_details["MessageModelList"]
          ap messages if (!messages.empty? && messages.to_s.include?("ERROR"))
        end
        order_details
      else
        #Return empty array rather than try to make an empty request
        []
      end
    else
      puts "ERROR: ID list is not an array"
    end
  end

  def save_order(order_json)
    order = RakutenOrder.find_by(order_id: order_json["orderNumber"])
    order ||= RakutenOrder.new(order_id: order_json["orderNumber"])
    order.assign_attributes({
        order_time: DateTime.parse(order_json["orderDatetime"]),
        arrival_date: (order_json["deliveryDate"].nil? ? nil : Date.parse(order_json["deliveryDate"])),
        ship_dates: order_json["PackageModelList"].map{|pkg| pkg["ShippingModelList"].map{|ship| Date.parse(ship["shippingDate"]) unless ship["shippingDate"].nil? } }.flatten.compact.uniq,
        status: order_json["orderProgress"],
        data: order_json
      })
    order.save
  end

  def process_orders(orders)
    orders.each do |order_json|
      begin
        save_order(order_json)
      rescue => e
        ap e
        ap e.backtrace
        ap e
      end
    end
  end

  def shipping_days(prefecture)
    days = 1
    shipping_days_hash = {
    %w( 北海道 青森県 岩手県 秋田県 ) => 2, # 北海道
    %w( 山形県 宮城県 福島県 ) => 1, # 南北
    %w( 茨城県 栃木県 群馬県 山梨県 埼玉県 千葉県 東京都 神奈川県 ) => 1, # 関東
    %w( 新潟県 長野県 ) => 1, # 信越
    %w( 富山県 石川県 福井県 ) => 1, # 北陸
    %w( 岐阜県 静岡県 愛知県 三重県 ) => 1, # 中部
    %w( 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県 ) => 1, # 関西
    %w( 鳥取県 島根県 岡山県 広島県 山口県 ) => 1, # 中国
    %w( 徳島県 香川県 愛媛県 高知県 ) => 1, # 四国
    %w( 福岡県 佐賀県 熊本県 大分県 宮崎県 ) => 1, # 九州
    %w( 長崎県 鹿児島県 沖縄県 ) => 2} # 九州・沖縄
    shipping_days_hash.each { |pref_arr, new_days| days = new_days if pref_arr.include?(prefecture) }
    days
  end

  def enum_arrival_times(integer)
    {
      '午前中' => 0,
      '14:00-16:00' => 1,
      '18:00-20:00' => 2,
    }[integer]
  end

  def earliest_arrival(prefecture, city)
    # {"prefecture" => { "city" => [days_to_arrival_integer, time_on_that_day_integer] } }
    # def add_hours_enum(integer)
    #   {
    #     0 => 12.hours,
    #     1 => 16.hours,
    #     2 => 18.hours}[integer]
    # end
    arrival_hash = {
      # 北海道
      "北海道" => {
        base: [2, 0],
        "奥尻郡" => [2, 2]},
      # 北南北
      "青森県" => {base: [2, 0]},
      "岩手県" => {base: [2, 0]},
      "秋田県" => {base: [2, 0]},
      # 南東北
      "宮城県" => {base: [1, 1]},
      "山形県" => {
        base: [1, 2],
        "上山市" => [1, 1],
        "寒河江市" => [1, 1],
        "天童市" => [1, 1],
        "東根市" => [1, 1],
        "村山市" => [1, 1],
        "山形市" => [1, 1]},
      "福島県" => {base: [1, 2],
        "会津若松市" => [1, 1],
        "安達郡" => [1, 1],
        "大沼郡" => [1, 1],
        "河沼郡" => [1, 1],
        "喜多方市" => [1, 1],
        "郡山市" => [1, 1],
        "伊達郡" => [1, 1],
        "伊達市" => [1, 1],
        "二本松市" => [1, 1],
        "福島市" => [1, 1],
        "本宮市" => [1, 1],
        "耶麻市" => [1, 1]},
      # 関東
      "茨城県" => {base: [1, 1]},
      "栃木県" => {base: [1, 1]},
      "群馬県" => {
        base: [1, 1],
        "吾妻郡" => [1, 2]},
      "埼玉県" => {base: [1, 0]},
      "千葉県" => {base: [1, 0]},
      "神奈川県" => {base: [1, 0]},
      "東京都" => {base: [1, 0]},
      "山梨県" => {base: [1, 0]},
      # 信越
      "新潟県" => {base: [1, 1]},
      "長野県" => {base: [1, 0]},
      # 北陸
      "富山県" => {base: [1, 0]},
      "石川県" => {base: [1, 0]},
      "福井県" => {base: [1, 0]},
      # 中部
      "岐阜県" => {base: [1, 0]},
      "静岡県" => {base: [1, 0]},
      "愛知県" => {base: [1, 0]},
      "三重県" => {base: [1, 0]},
      # 関西
      "滋賀県" => {base: [1, 0]},
      "京都府" => {base: [1, 0]},
      "大阪府" => {base: [1, 0]},
      "兵庫県" => {base: [1, 0]},
      "奈良県" => {base: [1, 0]},
      "和歌山県" => {base: [1, 0]},
      # 中国
      "鳥取県" => {base: [1, 0]},
      "島根県" => {
        base: [1, 0],
        "隠岐郡" => [1, 1]},
      "岡山県" => {base: [1, 0]},
      "広島県" => {base: [1, 0]},
      "山口県" => {base: [1, 0]},
      # 四国
      "徳島県" => {base: [1, 0]},
      "香川県" => {base: [1, 0]},
      "愛媛県" => {base: [1, 0]},
      "高知県" => {base: [1, 0]},
      # 九州
      "福岡県" => {base: [1, 0]},
      "佐賀県" => {base: [1, 1]},
      "長崎県" => {
        base: [1, 1],
        "小値賀島" => [2, 2],
        "五島市" => [2, 2],
        "対馬市" => [2, 0],
        "南松浦郡" => [2, 2]},
      "熊本県" => {
        base: [1, 1],
        "天草郡" => [1, 2],
        "天草市" => [1, 2]},
      "大分県" => {
        base: [1, 1],
        "中津市" => [1, 0]},
      "宮崎県" => {base: [1, 1]},
      "鹿児島県" => {
        base: [1, 1],
        "奄美市" => [2, 0],
        "大島郡" => [2, 1],
        "大島郡龍郷町" => [2, 0],
        "熊毛郡南種子町" => [2, 2],
        "熊毛郡" => [2, 2],
        "熊西之表市" => [2, 2]},
      # 沖縄県
      "沖縄県" => {
        base: [2, 0],
        "石垣市" => [2, 2],
        "島尻郡" => [2, 1],
        "宮古島市" => [2, 2]}

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

  def knife_model
    # "WrappingModel1" =>
    {
      "title" => 2, #ribbon setting
      "name" => "牡蠣ナイフセット", #name
      "price" => 220, #price
      "includeTaxFlag" => 1, #10% tax rate setting
      "deleteWrappingFlag" => 0
        }
  end

  def item_frozen?(manageNumber)
    {
      '10000018' => false, #m1
      '10000001' => false, #m2
      '10000035' => false, #tm2
      '10000002' => false, #m3
      '10000003' => false, #m4
      '10000027' => true, #p1
      '10000030' => true, #p2
      '10000028' => true, #p3
      '10000029' => true, #p4
      '10000026' => false, #k10
      '10000015' => false, #k10
      '10000004' => false, #k20
      '10000005' => false, #k30
      '10000025' => false, #k40
      '10000006' => false, #k50
      '10000040' => false, #k100
      '10000031' => true, #pk10
      '10000037' => true, #pk20
      '10000038' => true, #pk30
      '10000039' => true, #pk40
      '10000041' => true, #pk50
      '10000042' => true, #pk100
      '10000007' => false, #s110
      '10000008' => false, #s120
      '10000022' => false, #s130
      '10000009' => false, #s220
      '10000023' => false, #s230
      '10000012' => false, #a350
      '10000013' => false, #a480
      '10000014' => false, #a560
      '10000017' => false, #em1
      '10000016' => false, #em2
      '10000010' => false, #kem1
      '10000011' => false, #kem2
      'barakaki_1k' => false, #bkar1
      'barakaki_2k' => false, #bkar1
      'barakaki_3k' => false, #bkar1
      'barakaki_5k' => false, #bkar1
      'boiltako800-1k' => false, #tako
      'boiltako-2-3biki' => false, #tako
      'reito_oyster_salmon' => true, #salmon
      'oyster38' => false, #oyster38
      'tsukudani' => false, #Tsukud3
      'tsukudani6' => false, #Tsukud6
      'sbt-10' => false, #sbt10
      'sbt-20' => false, #sbt20
      'sbt-30' => false, #sbt30
      'sbt-40' => false, #sbt40
      'sbt-50' => false, #sbt50
      'sbt-60' => false, #sbt60
      'sbt-70' => false, #sbt70
      'sbt-80' => false, #sbt80
      'sbt-90' => false, #sbt90
      'sbt-100' => false, #sbt100
    }[manageNumber]
  end

  def memo_product_name(manageNumber)
    {
      '10000018' => "1", #m1
      '10000001' => "2", #m2
      '10000035' => "2 TS", #tm2
      '10000002' => "3", #m3
      '10000003' => "4", #m4
      '10000027' => "p1", #p1
      '10000030' => "p2", #p2
      '10000028' => "p3", #p3
      '10000029' => "p4", #p4
      '10000026' => "10", #k10
      '10000015' => "10", #k10
      '10000004' => "20", #k20
      '10000005' => "30", #k30
      '10000025' => "40", #k40
      '10000006' => "50", #k50
      '10000040' => "100", #k100
      '10000031' => "p10", #pk10
      '10000037' => "p20", #pk20
      '10000038' => "p30", #pk30
      '10000039' => "p40", #pk40
      '10000041' => "p50", #pk50
      '10000042' => "p100", #pk100
      '10000007' => "1,10", #s110
      '10000008' => "1,20", #s120
      '10000022' => "1,30", #s130
      '10000009' => "2,20", #s220
      '10000023' => "2,30", #s230
      '10000012' => "a350", #a350
      '10000013' => "a480", #a480
      '10000014' => "a600", #a600
      '10000017' => "ebi m80gx5", #em1
      '10000016' => "ebi m80gx3", #em2
      '10000010' => "ebi k80gx4", #kem1
      '10000011' => "ebi k80gx8", #kem2
      'barakaki_1k' => "小1kg", #bkar1
      'barakaki_2k' => "小2kg", #bkar1
      'barakaki_3k' => "小3kg", #bkar1
      'barakaki_5k' => "小5kg", #bkar1
      'boiltako800-1k' => "Lたこ", #Ltako
      'boiltako-2-3biki' => "Mたこ", #MTako
      'reito_oyster_salmon' => "サーモン", #salmon
      'oyster38' => 'ソース', #oyster38'
      'tsukudani' => '佃煮x3', #Tsukud3
      'tsukudani6' => '佃煮x6', #Tsukud6
      'sbt-10' => '三倍体10', #sbt10
      'sbt-20' => '三倍体20', #sbt20
      'sbt-30' => '三倍体30', #sbt30
      'sbt-40' => '三倍体40', #sbt40
      'sbt-50' => '三倍体50', #sbt50
      'sbt-60' => '三倍体60', #sbt60
      'sbt-70' => '三倍体70', #sbt70
      'sbt-80' => '三倍体80', #sbt80
      'sbt-90' => '三倍体90', #sbt90
      'sbt-100' => '三倍体100', #sbt100
    }[manageNumber]
  end

  def get_substatus_list
    # https://webservice.rms.rakuten.co.jp/merchant-portal/view?contents=/ja/common/1-1_service_index/rakutenpayorderapi/getsubstatuslist

    response = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/getSubStatusList/",
    :headers => @auth_header,
    :body => nil.to_json)
    ap response.parsed_response
  end

  def simple_item_name(manageNumber)
    {
      '10000018' => "坂越産 生牡蠣むき身500g×1", #m1
      '10000001' => "坂越産 生牡蠣むき身500g×2", #m2
      '10000035' => "坂越産 生牡蠣むき身500g×2 (TS)", #tm2
      '10000002' => "坂越産 生牡蠣むき身500g×3", #m3
      '10000003' => "坂越産 生牡蠣むき身500g×4", #m4
      '10000027' => "坂越産 冷凍牡蠣むき身500g×1", #p1
      '10000030' => "坂越産 冷凍牡蠣むき身500g×2", #p2
      '10000028' => "坂越産 冷凍牡蠣むき身500g×3", #p3
      '10000029' => "坂越産 冷凍牡蠣むき身500g×4", #p4
      '10000015' => "坂越産 殻付き生牡蠣 10個", #k10
      '10000004' => "坂越産 殻付き生牡蠣 20個", #k20
      '10000005' => "坂越産 殻付き生牡蠣 30個", #k30
      '10000025' => "坂越産 殻付き生牡蠣 40個", #k40
      '10000006' => "坂越産 殻付き生牡蠣 50個", #k50
      '10000040' => "坂越産 殻付き生牡蠣 100個", #k100
      '10000031' => "坂越産 冷凍殻付き牡蠣 10個", #pk10
      '10000037' => "坂越産 冷凍殻付き牡蠣 20個", #pk20
      '10000038' => "坂越産 冷凍殻付き牡蠣 30個", #pk30
      '10000039' => "坂越産 冷凍殻付き牡蠣 40個", #pk40
      '10000041' => "坂越産 冷凍殻付き牡蠣 50個", #pk50
      '10000042' => "坂越産 冷凍殻付き牡蠣 100個", #pk100
      '10000007' => "坂越産 生牡蠣 むき身500g×1 + 殻付き10個", #s110
      '10000008' => "坂越産 生牡蠣 むき身500g×1 + 殻付き20個", #s120
      '10000022' => "坂越産 生牡蠣 むき身500g×1 + 殻付き30個", #s130
      '10000009' => "坂越産 生牡蠣 むき身500g×2 + 殻付き20個", #s220
      '10000023' => "坂越産 生牡蠣 むき身500g×2 + 殻付き30個", #s230
      'boiltako800-1k' => "兵庫県産 ボイルたこ Lサイズ (800g~1kg)", #tako
      'boiltako-2-3biki' => "兵庫県産 ボイルたこ Mサイズ (2~3匹) 1kg", #tako
      '10000012' => "兵庫県産 焼き穴子 350g", #a350
      '10000013' => "兵庫県産 焼き穴子 480g", #a480
      '10000014' => "兵庫県産 焼き穴子 600g", #a600
      '10000016' => "兵庫県産 むき干しえび 80g×3", #em3
      '10000017' => "兵庫県産 むき干しえび 80g×5", #em5
      '10000010' => "兵庫県産 殻付き干しえび 80g×4", #kem5
      '10000011' => "兵庫県産 殻付き干しえび 80g×8", #kem10
      'barakaki_1k' => "坂越産 殻付き生牡蠣 1kg", #bkar1
      'barakaki_2k' => "坂越産 殻付き生牡蠣 2kg", #bkar1
      'barakaki_3k' => "坂越産 殻付き生牡蠣 3kg", #bkar1
      'barakaki_5k' => "坂越産 殻付き生牡蠣 5kg", #bkar1
      'reito_oyster_salmon' => "坂越産 冷凍オイスターサーモン", #salmon
      'oyster38' => "Oyster38 オイスターソース", #Oyster38
      'tsukudani' => "サムライ佃煮x3", #Tsukud3
      'tsukudani6' => "サムライ佃煮x6", #Tsukud6
      'sbt-10' => 'SAMURAI GOLD 殻付き牡蠣 10個', #sbt10
      'sbt-20' => 'SAMURAI GOLD 殻付き牡蠣 20個', #sbt20
      'sbt-30' => 'SAMURAI GOLD 殻付き牡蠣 30個', #sbt30
      'sbt-40' => 'SAMURAI GOLD 殻付き牡蠣 40個', #sbt40
      'sbt-50' => 'SAMURAI GOLD 殻付き牡蠣 50個', #sbt50
      'sbt-60' => 'SAMURAI GOLD 殻付き牡蠣 60個', #sbt60
      'sbt-70' => 'SAMURAI GOLD 殻付き牡蠣 70個', #sbt70
      'sbt-80' => 'SAMURAI GOLD 殻付き牡蠣 80個', #sbt80
      'sbt-90' => 'SAMURAI GOLD 殻付き牡蠣 90個', #sbt90
      'sbt-100' => 'SAMURAI GOLD 殻付き牡蠣 100個' #sbt100
    }[manageNumber]
  end

  def get_extra_cost(prefecture, item_id)
    item_extra_cost = {
      '10000018' => 1210, #m1
      '10000001' => 1210, #m2
      '10000035' => 1210, #tm2
      '10000002' => 1210, #m3
      '10000003' => 1320, #m4
      '10000027' => 660, #p1
      '10000030' => 1210, #p2
      '10000028' => 1210, #p3
      '10000029' => 1210, #p4
      '10000015' => 660, #k10
      '10000004' => 1210, #k20
      '10000005' => 1210, #k30
      '10000025' => 1320, #k40
      '10000006' => 1320, #k50
      '10000040' => 1320, #k100
      '10000031' => 660, #pk10
      '10000037' => 1210, #pk20
      '10000038' => 1210, #pk30
      '10000039' => 1320, #pk40
      '10000041' => 1320, #pk50
      '10000042' => 1320, #pk100
      '10000007' => 1210, #s110
      '10000008' => 1210, #s120
      '10000022' => 1210, #s130
      '10000009' => 1320, #s220
      '10000023' => 1320, #s230
      'boiltako800-1k' => 1210, #tako
      'boiltako-2-3biki' => 1210, #tako
      '10000012' => 1210, #a350
      '10000013' => 1210, #a480
      '10000014' => 1210, #a600
      '10000017' => 1210, #em5
      '10000016' => 1210, #em3
      '10000010' => 1210, #kem5
      '10000011' => 1320, #kem10
      'barakaki_1k' => 660, #bkar1
      'barakaki_2k' => 1210, #bkar1
      'barakaki_3k' => 1210, #bkar1
      'barakaki_5k' => 1320, #bkar1
      'reito_oyster_salmon' => 1210, #salmon
      'oyster38' => 0, #sauce
      'tsukudani' => 660, #tsukudani3
      'tsukudani6' => 0, #Tsukud6
      'sbt-10' => 660, #sbt10
      'sbt-20' => 1210, #sbt20
      'sbt-30' => 1210, #sbt30
      'sbt-40' => 1320, #sbt40
      'sbt-50' => 1320, #sbt50
      'sbt-60' => 1320, #sbt60
      'sbt-70' => 1320, #sbt70
      'sbt-80' => 1320, #sbt80
      'sbt-90' => 1320, #sbt90
      'sbt-100' => 1320 #sbt100
    }[item_id]
    %w( 北海道 青森県 岩手県 秋田県 沖縄県 ).include?(prefecture) ? item_extra_cost : 0
  end

  def set_details(order_details)

    def add_hours_enum(integer)
      {
        0 => 12.hours,
        1 => 16.hours,
        2 => 18.hours}[integer]
    end

    def add_hours_string(string)
      {
        '午前中' => 12.hours,
        '14:00-16:00' => 16.hours,
        '16:00-18:00' => 18.hours,
        '18:00-20:00' => 20.hours,
        '19:00-21:00' => 21.hours,
        0 => 21.hours,
        1 => 12.hours,
        2 => 21.hours,
        1416 => 16.hours,
        1618 => 18.hours,
        1820 => 20.hours,
        1921 => 21.hours
      }[string]
    end

    order_details.flatten.each do |order|
      errors = Hash.new
      if order["orderProgress"] == 100 && order["subStatusId"] != 15822
        order_id = order["orderNumber"]
        ## CALCULATE AND UPDATE SHIPPING AND ARRIVAL DATES
        @arrival_date = order["deliveryDate"]
        selected_choices = order["PackageModelList"].map{|package| package["ItemModelList"].map{ |item| item["selectedChoice"] }}.flatten
        date_year = Time.zone.today.year
        end_of_year_shipping_hash = {
          ':12/25お届け　ご指定いただけます' => "#{date_year}-12-25",
          ':12/26お届け　ご指定いただけます' => "#{date_year}-12-26",
          ':12/27お届け　ご指定いただけます' => "#{date_year}-12-27",
          ':12/28お届け　ご指定いただけます' => "#{date_year}-12-28",
          ':12/29お届け　ご指定いただけます' => "#{date_year}-12-29",
          ':12/30お届け　ご指定いただけます' => "#{date_year}-12-30"}
        end_of_year = selected_choices.map{|select_text| end_of_year_shipping_hash.map{|date_text, date_value| date_value if (!select_text.nil? && select_text.include?(date_text))}.compact }.flatten.first
        end_of_year_memo = end_of_year ? end_of_year.to_time.strftime('%m月%d日') : ''
        @arrival_date = end_of_year.to_date unless end_of_year.nil?
        # Shipping base time is based on a cutoff from 8AM on the morning of processing
        shipping_base_date = (Time.zone.now.hour > 6) ? Time.zone.tomorrow : Time.zone.today
        @impossible_delivery_time = false
        isolated_island = (order["isolatedIslandFlag"] == 1)
        cod_shipping = order["SettlementModel"]["settlementMethod"] == "代金引換"
        order_items = order["PackageModelList"].map{|pkg| pkg["ItemModelList"].map{|item| item["manageNumber"]}}.flatten
        ship_wait_products = %w[barakaki_1k barakaki_2k barakaki_3k barakaki_5k]
        product_ship_wait = ship_wait_products.any?{|product| order_items.include?(product)}
        shipping_date_wait = ( order["SettlementModel"]["settlementMethod"] == "銀行振込" || order["SettlementModel"]["settlementMethod"].include?('前払') || product_ship_wait )
        @packages = []
        old_order_shipping = {"orderNumber" => order_id}
        destinations = []
        order["PackageModelList"].each_with_index do |package, i|
          arrival_prefecture = package["SenderModel"]["prefecture"]
          destinations << [arrival_prefecture, package["SenderModel"]["city"]]
          memo_set_time = order["remarks"][/[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}/]
          memo_set_time = '午前中' unless order["remarks"][/午前中/].nil?
          memo_set_time = order["shippingTerm"] if memo_set_time.nil?
          # memo_set_date = order["remarks"][/[0-9]{4}-(1[0-2]|0[1-9])-(3[01]|[12][0-9]|0[1-9])/]
          earliest_arrival_array = earliest_arrival(arrival_prefecture, package["SenderModel"]["city"], errors)
          earliest_possible_arrival = shipping_base_date.to_time + earliest_arrival_array[0].days + add_hours_enum(earliest_arrival_array[1])
          ##########DATE TIME SETTING##############
          # Unspecified arrival in ["deliveryDate"]
          if @arrival_date.nil?
            # Set to base date, that being tomorrow
            shipping_date = shipping_base_date
            # Add time necessary to find earliest arrival
            @arrival_date = (shipping_base_date + earliest_arrival_array[0].days)
            # Now that we have a desired estimated arrival time, let's check if it matches their desired arrival time
            if memo_set_time && (memo_set_time != 0)
              set_time_arrival = @arrival_date.to_time + add_hours_string(memo_set_time)
              # If the arrival time they set isn't possible, then we need to add a day to our arrival time setting
              if (set_time_arrival < earliest_possible_arrival)
                @arrival_date += 1.day
              end
            end
          # Specified arrival date, but no time
          elsif @arrival_date && memo_set_time.nil?
            @arrival_date = Date.parse(@arrival_date) unless @arrival_date.is_a?(Date)
            shipping_date = (@arrival_date - earliest_arrival_array[0].days)
          # Specified arrival date and time
          elsif @arrival_date && memo_set_time
            @arrival_date = Date.parse(@arrival_date) unless @arrival_date.is_a?(Date)
            set_time_arrival = @arrival_date.to_time + add_hours_string(memo_set_time)

            destination_min_arrival_time_hours = add_hours_enum(earliest_arrival_array[1])
            set_arrival_time_hours = add_hours_string(memo_set_time)

            # Check if setting possible
            if (set_time_arrival < earliest_possible_arrival) #impossible setting
              # Discrepancy/conflict with customer set time
              # When the customer set time is not possible to arrive in time
              @impossible_delivery_time = true
              # Have to add a day to the set arrival day so it can arrive at the desired set time
              @arrival_date += 1.day
            end
            shipping_date = @arrival_date - earliest_arrival_array[0].days
            shipping_date -= 1.day if (destination_min_arrival_time_hours > set_arrival_time_hours)
          end
          #########################################
          old_order_shipping["BasketidModelList"] = [{ "basket_id" => package["basketId"], "ShippingModelList" => package["ShippingModelList"]}]
          choice_cleanup = [
            ["お届けについて、年内は【１２月３０日最終】、年始は【１月７日より】となります。数量に達し次第、随時締め切りますので、下記よりご確認の上、ご指定下さい。締め切った日をご指定いただいた場合、こちらからお届け日をお知らせいたします。:了承した", ""],
            ["年末年始お届けについてはこちらをご確認下さい。", ""],
            ["Oyster38 オイスターソース セット", "Oyster38"],
            ["サムライオイスター佃煮セット", "佃煮"]
          ]
          updated_item_list_model = []
          package["ItemModelList"].each do |item_hash|
            new_hash = item_hash
            choice_cleanup.each{|arr| new_hash["selectedChoice"].gsub!(arr[0], arr[1])} if new_hash["selectedChoice"]
            new_hash["itemName"] = simple_item_name(item_hash["manageNumber"])
            new_hash["taxRate"] = 0.08
            updated_item_list_model << new_hash
          end
          sender_model_fix = Hash.new
          package["SenderModel"].each do |k,v|
            fixed_v = v
            unless fixed_v.nil? || !fixed_v.is_a?(String)
              error_characters = {
                '&' => ' and ',
                '・' => '.'
              }
              error_characters.each do |ec, fc|
                fixed_v.gsub(ec, fc)
              end
              fixed_v = ' ' if fixed_v.nil?
            end
            sender_model_fix[k] = fixed_v
          end
          basket_hash = {
            sender_model: sender_model_fix,
            basket_id: package["basketId"],
            noshi: package["noshi"],
            delivery_cost: package["deliveryPrice"],
            shipping_date: shipping_date.to_s,
            item_model_list: updated_item_list_model,
            items_list: package["ItemModelList"].map{ |item| {id: item["manageNumber"], count: item["units"], selection: item["selectedChoice"], extra_delivery_cost: get_extra_cost(package["SenderModel"]["prefecture"], item["manageNumber"])} }
          }
          @packages << basket_hash
        end
        includes_anago = @packages.map{|pkg| pkg[:items_list].map{|item| item[:item_name] }}.flatten.join(' ').include?('穴子')
        new_year_delivery = selected_choices.map{|choice| ((choice.include?('1月以降の発送OK。') || (choice.include?('):1月の発送希望'))) ? true : false) unless choice.nil? }.compact.include?(true)
        new_order_shipping = {
          "orderNumber" => order_id,
          "BasketidModelList" => @packages.map.with_index{|pkg, i| {
            "basketId" => pkg[:basket_id],
            "ShippingModelList" => [{
                "shippingDetailId" => old_order_shipping.dig("BasketidModelList", i, "ShippingModelList", i, "shippingDetailId").nil? ? nil : old_order_shipping["BasketidModelList"][i]["ShippingModelList"][i]["shippingDetailId"],
                "deliveryCompany" => "1001",
                "deliveryCompanyName" => "ヤマト運輸",
                "shippingDate" => (shipping_date_wait || includes_anago || new_year_delivery) ? nil : pkg[:shipping_date]
                }]
              }
            }
          }
        ## https://webservice.rms.rakuten.co.jp/merchant-portal/view?contents=/ja/common/1-1_service_index/rakutenpayorderapi/updateordershipping
        response = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShipping/",
          :headers => @auth_header,
          :body => new_order_shipping.to_json)
        errors[:shipping] = response.parsed_response unless response["MessageModelList"].first["messageType"] == "INFO"

        ## Add Oyster Knife and Simplify Item Name (special rules require coupons and daibiki tax)
        knife_count = @packages.map{|pkg| pkg[:items_list].map{|item| item[:selection].split("\n") if item[:selection]}}.flatten.map{|choice| ((choice.include?('牡蠣ナイフ') && choice.include?('希望する')) ? 1 : 0) unless choice.nil? }.compact.inject(0, :+)
        tsukudani_count = @packages.map{|pkg| pkg[:items_list].map{|item| item[:selection].split("\n") if item[:selection]}}.flatten.map{|choice| ((choice.include?('佃煮') && choice.include?('希望する')) ? 1 : 0) unless choice.nil? }.compact.inject(0, :+)
        sauce_count = @packages.map{|pkg| pkg[:items_list].map{|item| item[:selection].split("\n") if item[:selection]}}.flatten.map{|choice| ((choice.include?('Oyster38') && choice.include?('希望する')) ? 1 : 0) unless choice.nil? }.compact.inject(0, :+)
        coupon_model = order["CouponModelList"]
        if cod_shipping
          new_sender_model = {
            "orderNumber" => order_id,
            "PackageModelList" => @packages.map{|pkg| {
                "basketId" => pkg[:basket_id],
                "postageTaxRate" => 0.1,
                "deliveryPrice" => pkg[:delivery_cost],
                "postagePrice" => (pkg[:items_list].map{|item| item[:extra_delivery_cost]}.inject(0, :+)),
                "deliveryTaxRate" => 0.1, #required for daibiki, disregards for others
                "SenderModel" => pkg[:sender_model],
                "ItemModelList" => pkg[:item_model_list]
              }
            }
          }
        else
          new_sender_model = {
            "orderNumber" => order_id,
            "PackageModelList" => @packages.map{|pkg| {
                "basketId" => pkg[:basket_id],
                "postageTaxRate" => 0.1,
                "postagePrice" => (pkg[:items_list].map{|item| item[:extra_delivery_cost]}.inject(0, :+)),
                "SenderModel" => pkg[:sender_model],
                "ItemModelList" => pkg[:item_model_list]
              }
            }
          }
        end
        # 125 characters can fit in the wrapping model name
        if knife_count > 0
          new_sender_model["WrappingModel1"] = {
            "title" => 2,
            "name" => "牡蠣ナイフセット#{('× ' + knife_count.to_s) if (knife_count > 1)}",
            "price" => (250 * knife_count),
            "taxRate" => 0.08,
            "includeTaxFlag" => 1,
            "deleteWrappingFlag" => 0
            }
        end
        if tsukudani_count > 0
          knife_count > 0 ? wrapping_model = "WrappingModel2" : wrapping_model = "WrappingModel1"
          new_sender_model[wrapping_model] = {
            "title" => 2,
            "name" => "サムライオイスター佃煮#{('× ' + tsukudani_count.to_s) if (tsukudani_count > 1)}",
            "price" => (650 * tsukudani_count),
            "taxRate" => 0.08,
            "includeTaxFlag" => 1,
            "deleteWrappingFlag" => 0
            }
        end
        if sauce_count > 0
          combine = ((knife_count > 0) && (tsukudani_count > 0))
          if combine
            new_sender_model["WrappingModel2"]["name"] += " Oyster38 オイスターソース#{('× ' + sauce_count.to_s) if (sauce_count > 1)}"
            new_sender_model["WrappingModel2"]["price"] += (1500 * sauce_count)
          else
            ((knife_count > 0) || (tsukudani_count > 0)) ? wrapping_model = "WrappingModel2" : wrapping_model = "WrappingModel1"
            new_sender_model[wrapping_model] = {
              "title" => 2,
              "name" => "Oyster38 オイスターソース#{('× ' + sauce_count.to_s) if (sauce_count > 1)}",
              "price" => (1500 * sauce_count),
              "taxRate" => 0.08,
              "includeTaxFlag" => 1,
              "deleteWrappingFlag" => 0
              }
          end
        end
        unless coupon_model.nil? || coupon_model.empty?
          new_sender_model["CouponModelList"]= order["CouponModelList"]
        end
        response = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSender/",
          :headers => @auth_header,
          :body => new_sender_model.to_json)
        errors[:sender_model] = response.parsed_response unless response["MessageModelList"].first["messageType"] == "INFO"

        ## SET MEMO, SHIP DATE, MEMO(ERROR, PAYMENT METHOD, GIFT, COOL/FROZEN, COUNTS), AND UPDATE SUBSTATUS COMPLETE
        frozen_check = @packages.map{|pkg| pkg[:items_list].map{|item| item_frozen?(item[:id])}}.flatten.compact.include?(true)
        payment_method = order["SettlementModel"]["settlementMethod"]
        remarks = order["remarks"].delete("\n")[/(?<=\[メッセージ添付希望・他ご意見、ご要望がありましたらこちらまで:\]).*/]
        memo_product_names = @packages.map{|pkg| pkg[:items_list].map{|item| memo_product_name(item[:id]) + "#{('x' + item[:count].to_s) if item[:count].to_i > 1}" }}.flatten.join(' ')
        memo_date_memo = order["remarks"].delete("\n")[/(?<=\[配送日時指定:\]).*(?=\[メッセージ)/].sub(/[0-9]{4}-(1[0-2]|0[1-9])-(3[01]|[12][0-9]|0[1-9])/, '').sub(/\(.\)(午前中)/,'').sub(/\(.\)/,'').sub(/[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}/,'').sub('指定なし', '')
        has_noshi = !@packages.map{|pkg| pkg[:noshi] }.compact.empty?
        gift = !order["giftCheckFlag"].zero?
        there_are_errors = !errors.empty?
        additional_shipping = @packages.map{|pkg| pkg[:items_list].map{|item| item[:extra_delivery_cost]}.inject(0, :+) > 0 }.include?(true)
        days = @packages.map{|pkg| (@arrival_date - Date.parse(pkg[:shipping_date])).to_i }.max
        memo = "#{memo_product_names} #{' ソース同梱' if (sauce_count > 0)}#{' 佃煮同梱' if (tsukudani_count > 0)}#{' 時間指定無理' if @impossible_delivery_time}#{' 1月OK' if new_year_delivery}#{' ' + days.to_s + 'D' if days > 1}#{' 離島' if isolated_island }#{' 送料追加' if additional_shipping}#{' ナイフ' if knife_count > 0}#{' のし' if has_noshi}#{' 冷凍' if frozen_check}#{' ' + payment_method if (payment_method == "代金引換" || payment_method == "銀行振込")}#{' 前払' if payment_method.include?('前払')}#{' ギフト' if gift}#{' 備考あり' unless remarks.empty? }#{' 時間指定備考あり' unless memo_date_memo.empty?}#{' 自動処理エラー' if there_are_errors }#{ " #{end_of_year_memo}届" unless end_of_year_memo.empty?}"
        #same_sender = !order["equalSenderFlag"].zero?
        #several_sender = !order["severalSenderFlag"].zero?
        order_memo = {
          "orderNumber" => order_id,
          "subStatusId" => 15822,
          "deliveryClass" => (frozen_check ? 3 : 2),
          "deliveryDate" => (shipping_date_wait || includes_anago || new_year_delivery) ? nil : (end_of_year ? end_of_year : @arrival_date.to_s),
          "memo" => memo
        }
        # https://webservice.rms.rakuten.co.jp/merchant-portal/view?contents=/ja/common/1-1_service_index/rakutenpayorderapi/updateordermemo
        response = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderMemo/",
          :headers => @auth_header,
          :body => order_memo.to_json)
        errors[:order_memo] = response.parsed_response unless response["MessageModelList"].first["messageType"] == "INFO"
        ap errors
      end
    end; nil
  end

  def print_details(order_details, debug_time = false)
    # Easy debugging and fixing errors using this method:
    # order_details = RakutenAPI.new.get_details_by_ids(["###"])
    # RakutenAPI.new.print_details(order_details)
    # RakutenAPI.new.print_details(RakutenAPI.new.get_details_by_ids(RakutenAPI.new.get_unprocessed_shinki))

    def add_hours_enum(integer)
      {
        0 => 12.hours,
        1 => 16.hours,
        2 => 18.hours}[integer]
    end

    def add_hours_string(string)
      {
        '午前中' => 12.hours,
        '14:00-16:00' => 16.hours,
        '16:00-18:00' => 18.hours,
        '18:00-20:00' => 20.hours,
        '19:00-21:00' => 21.hours,
        0 => 21.hours,
        1 => 12.hours,
        2 => 21.hours,
        1416 => 16.hours,
        1618 => 18.hours,
        1820 => 20.hours,
        1921 => 21.hours
      }[string]
    end

    order_details.flatten.each do |order|
      errors = Hash.new
      # Comment out non-processing of orders already processed
      if true #order["orderProgress"] == 100 && order["subStatusId"] != 15822
        order_id = order["orderNumber"]
        ap order_id
        ## CALCULATE AND UPDATE SHIPPING AND ARRIVAL DATES
        @arrival_date = order["deliveryDate"]
        selected_choices = order["PackageModelList"].map{|package| package["ItemModelList"].map{ |item| item["selectedChoice"] }}.flatten
        new_year_date_year = (Time.zone.today.month > 1 ? (Time.zone.today.year + 1) : (Time.zone.today.year))
        date_year = Time.zone.today.year
        end_of_year_shipping_hash = {
          ':12/25お届け　ご指定いただけます' => "#{date_year}-12-25",
          ':12/26お届け　ご指定いただけます' => "#{date_year}-12-26",
          ':12/27お届け　ご指定いただけます' => "#{date_year}-12-27",
          ':12/28お届け　ご指定いただけます' => "#{date_year}-12-28",
          ':12/29お届け　ご指定いただけます' => "#{date_year}-12-29",
          ':12/30お届け　ご指定いただけます' => "#{date_year}-12-30"}
        end_of_year = selected_choices.map{|select_text| end_of_year_shipping_hash.map{|date_text, date_value| date_value if (!select_text.nil? && select_text.include?(date_text))}.compact }.flatten.first
        end_of_year_memo = end_of_year ? end_of_year.to_time.strftime('%m月%d日') : ''
        @arrival_date = end_of_year.to_date unless end_of_year.nil?
        ap end_of_year if debug_time
        # Shipping base time is based on a cutoff from 8AM on the morning of processing
        shipping_base_date = (DateTime.now.hour > 11) ? Date.tomorrow : Time.zone.today
        @impossible_delivery_time = false
        isolated_island = (order["isolatedIslandFlag"] == 1)
        cod_shipping = order["SettlementModel"]["settlementMethod"] == "代金引換"
        shipping_date_wait = ( order["SettlementModel"]["settlementMethod"] == "銀行振込" || order["SettlementModel"]["settlementMethod"].include?('前払') )
        @packages = Array.new
        old_order_shipping = {"orderNumber" => order_id}
        destinations = Array.new
        order["PackageModelList"].each_with_index do |package, i|
          arrival_prefecture = package["SenderModel"]["prefecture"]
          destinations << [arrival_prefecture, package["SenderModel"]["city"]]
          memo_set_time = order["remarks"][/[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}/]
          memo_set_time = '午前中' unless order["remarks"][/午前中/].nil?
          memo_set_time = order["shippingTerm"] if memo_set_time.nil?
          # memo_set_date = order["remarks"][/[0-9]{4}-(1[0-2]|0[1-9])-(3[01]|[12][0-9]|0[1-9])/]
          ap "Arrival prefecture: #{arrival_prefecture}, city: #{package["SenderModel"]["city"]}" if debug_time
          earliest_arrival_array = earliest_arrival(arrival_prefecture, package["SenderModel"]["city"])
          ap "Earliest arrival array result: #{earliest_arrival_array}" if debug_time
          earliest_possible_arrival = shipping_base_date.to_time + earliest_arrival_array[0].days + add_hours_enum(earliest_arrival_array[1])
          ##########DATE TIME SETTING##############
          # Unspecified arrival in ["deliveryDate"]
          if @arrival_date.nil?
            ap "Unspecified arrival date" if debug_time
            # Set to base date, that being tomorrow
            shipping_date = shipping_base_date
            ap shipping_date if debug_time
            # Add time necessary to find earliest arrival
            @arrival_date = (shipping_base_date + earliest_arrival_array[0].days)
            # Now that we have a desired estimated arrival time, let's check if it matches their desired arrival time
            if memo_set_time
              ap "Time set: #{memo_set_time}" if debug_time
              set_time_arrival = @arrival_date.to_time + add_hours_string(memo_set_time)
              # If the arrival time they set isn't possible, then we need to add a day to our arrival time setting
              if (set_time_arrival < earliest_possible_arrival)
                @arrival_date += 1.day
              end
            end
          # Specified arrival date, but no time
          elsif @arrival_date && memo_set_time.nil?
            ap "Specified arrival date, but no time" if debug_time
            @arrival_date = Date.parse(@arrival_date) unless @arrival_date.is_a?(Date)
            shipping_date = (@arrival_date - earliest_arrival_array[0].days)
          # Specified arrival date and time
          elsif @arrival_date && memo_set_time
            ap "Specified arrival date and time:" if debug_time
            ap "Is the set arrival date a date? #{@arrival_date.is_a?(Date)}" if debug_time
            ap "If it's already a date, it's an end of year selected choice order" if debug_time
            @arrival_date = Date.parse(@arrival_date) unless @arrival_date.is_a?(Date)
            set_time_arrival = @arrival_date.to_time + add_hours_string(memo_set_time)
            ap @arrival_date if debug_time
            ap memo_set_time if debug_time
            ap "Set time in hours" if debug_time
            set_arrival_time_hours = add_hours_string(memo_set_time)
            ap set_arrival_time_hours if debug_time
            ap "Destination minimum arrival in hours" if debug_time
            destination_min_arrival_time_hours = add_hours_enum(earliest_arrival_array[1])
            ap destination_min_arrival_time_hours if debug_time
            ap "Destination minimum is less than set time in hours?" if debug_time
            ap (destination_min_arrival_time_hours > set_arrival_time_hours) if debug_time
            ap "Set arrival" if debug_time
            ap set_time_arrival if debug_time
            # Check if setting possible
            if (set_time_arrival < earliest_possible_arrival) #impossible setting
              # Discrepancy/conflict with customer set time
              # When the customer set time is not possible to arrive in time
              @impossible_delivery_time = true
              # Have to add a day to the set arrival day so it can arrive at the desired set time
              @arrival_date += 1.day
            end
            ap @arrival_date if debug_time
            shipping_date = @arrival_date - earliest_arrival_array[0].days
            ap "A. Calculated #{destination_min_arrival_time_hours} destination min arrival" if debug_time
            ap "B. Calculated #{set_arrival_time_hours}" if debug_time
            ap "A > B ?: #{destination_min_arrival_time_hours > set_arrival_time_hours}" if debug_time
            shipping_date -= 1.day if (destination_min_arrival_time_hours > set_arrival_time_hours)
          end
          #########################################
          old_order_shipping["BasketidModelList"] = [{ "basket_id" => package["basketId"], "ShippingModelList" => package["ShippingModelList"]}]
          choice_cleanup = [
            ["お届けについて、年内は【１２月３０日最終】、年始は【１月７日より】となります。数量に達し次第、随時締め切りますので、下記項目よりご確認下さい。締め切った日をご指定いただいた場合、こちらからお届け日をお知らせいたします。:了承した\n", ""],
            ["年末年始お届けについて:", ""],
            ["12/24以前はご指定いただけます", '12/24以前指定'],
            ["Oyster38 オイスターソース セット", "Oyster38"],
            ["サムライオイスター佃煮セット", "佃煮"]
          ]
          updated_item_list_model = Array.new
          package["ItemModelList"].each do |item_hash|
            new_hash = item_hash
            choice_cleanup.each{|arr| new_hash["selectedChoice"].gsub!(arr[0], arr[1])} if new_hash["selectedChoice"]
            new_hash["itemName"] = simple_item_name(item_hash["manageNumber"])
            new_hash["taxRate"] = 0.08
            updated_item_list_model << new_hash
          end
          sender_model_fix = Hash.new
          package["SenderModel"].each do |k,v|
            fixed_v = v
            unless fixed_v.nil? || !fixed_v.is_a?(String)
              error_characters = {
                '&' => ' and ',
                '・' => '.'
              }
              error_characters.each do |ec, fc|
                fixed_v.gsub(ec, fc)
              end
              fixed_v = ' ' if fixed_v.nil?
            end
            sender_model_fix[k] = fixed_v
          end
          basket_hash = {
            sender_model: sender_model_fix,
            basket_id: package["basketId"],
            noshi: package["noshi"],
            delivery_cost: package["deliveryPrice"],
            shipping_date: shipping_date.to_s,
            item_model_list: updated_item_list_model,
            items_list: package["ItemModelList"].map{ |item| {id: item["manageNumber"], count: item["units"], selection: item["selectedChoice"], extra_delivery_cost: get_extra_cost(package["SenderModel"]["prefecture"], item["manageNumber"])} }
          }
          @packages << basket_hash
        end
        includes_anago = @packages.map{|pkg| pkg[:items_list].map{|item| item[:item_name] }}.flatten.join(' ').include?('穴子')
        new_year_delivery = selected_choices.map{|choice| ((choice.include?('1月以降の発送OK。') || (choice.include?('):1月の発送希望'))) ? true : false) unless choice.nil? }.compact.include?(true)
        ap "Is this a new year delivery? #{new_year_delivery}" if debug_time
        new_order_shipping = {
          "orderNumber" => order_id,
          "BasketidModelList" => @packages.map.with_index{|pkg, i| {
            "basketId" => pkg[:basket_id],
            "ShippingModelList" => [{
                "shippingDetailId" => old_order_shipping.dig("BasketidModelList", i, "ShippingModelList", i, "shippingDetailId").nil? ? nil : old_order_shipping["BasketidModelList"][i]["ShippingModelList"][i]["shippingDetailId"],
                "deliveryCompany" => "1001",
                "deliveryCompanyName" => "ヤマト運輸",
                "shippingDate" => (shipping_date_wait || includes_anago || new_year_delivery) ? nil : pkg[:shipping_date]
                }]
              }
            }
          }
        p 'New shipping will be:' if debug_time
        ap new_order_shipping if debug_time
        ## https://webservice.rms.rakuten.co.jp/merchant-portal/view?contents=/ja/common/1-1_service_index/rakutenpayorderapi/updateordershipping
        # response = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderShipping/",
        #   :headers => @auth_header,
        #   :body => new_order_shipping.to_json)
        # errors[:shipping] = response.parsed_response unless response["MessageModelList"].first["messageType"] == "INFO"

        ## Add Oyster Knife and Simplify Item Name (special rules require coupons and daibiki tax)
        knife_count = @packages.map{|pkg| pkg[:items_list].map{|item| item[:selection].split("\n") if item[:selection]}}.flatten.map{|choice| ((choice.include?('牡蠣ナイフ') && choice.include?('希望する')) ? 1 : 0) unless choice.nil? }.compact.inject(0, :+)
        tsukudani_count = @packages.map{|pkg| pkg[:items_list].map{|item| item[:selection].split("\n") if item[:selection]}}.flatten.map{|choice| ((choice.include?('佃煮') && choice.include?('希望する')) ? 1 : 0) unless choice.nil? }.compact.inject(0, :+)
        sauce_count = @packages.map{|pkg| pkg[:items_list].map{|item| item[:selection].split("\n") if item[:selection]}}.flatten.map{|choice| ((choice.include?('Oyster38') && choice.include?('希望する')) ? 1 : 0) unless choice.nil? }.compact.inject(0, :+)
        coupon_model = order["CouponModelList"]
        if cod_shipping
          new_sender_model = {
            "orderNumber" => order_id,
            "PackageModelList" => @packages.map{|pkg| {
                "basketId" => pkg[:basket_id],
                "postageTaxRate" => 0.1,
                "deliveryPrice" => pkg[:delivery_cost],
                "postagePrice" => (pkg[:items_list].map{|item| item[:extra_delivery_cost]}.inject(0, :+)),
                "deliveryTaxRate" => 0.1, #required for daibiki, disregards for others
                "SenderModel" => pkg[:sender_model],
                "ItemModelList" => pkg[:item_model_list]
              }
            }
          }
        else
          new_sender_model = {
            "orderNumber" => order_id,
            "PackageModelList" => @packages.map{|pkg| {
                "basketId" => pkg[:basket_id],
                "postageTaxRate" => 0.1,
                "postagePrice" => (pkg[:items_list].map{|item| item[:extra_delivery_cost]}.inject(0, :+)),
                "SenderModel" => pkg[:sender_model],
                "ItemModelList" => pkg[:item_model_list]
              }
            }
          }
        end
        # 125 characters can fit in the wrapping model name
        if knife_count > 0
          new_sender_model["WrappingModel1"] = {
            "title" => 2,
            "name" => "牡蠣ナイフセット#{('× ' + knife_count.to_s) if (knife_count > 1)}",
            "price" => (220 * knife_count),
            "taxRate" => 0.1,
            "includeTaxFlag" => 1,
            "deleteWrappingFlag" => 0
            }
        end
        if tsukudani_count > 0
          knife_count > 0 ? wrapping_model = "WrappingModel2" : wrapping_model = "WrappingModel1"
          new_sender_model[wrapping_model] = {
            "title" => 2,
            "name" => "サムライオイスター佃煮#{('× ' + tsukudani_count.to_s) if (tsukudani_count > 1)}",
            "price" => (650 * tsukudani_count),
            "taxRate" => 0.1,
            "includeTaxFlag" => 1,
            "deleteWrappingFlag" => 0
            }
        end
        if sauce_count > 0
          combine = ((knife_count > 0) && (tsukudani_count > 0))
          if combine
            new_sender_model["WrappingModel2"]["name"] += " Oyster38 オイスターソース#{('× ' + sauce_count.to_s) if (sauce_count > 1)}"
            new_sender_model["WrappingModel2"]["price"] += (1500 * sauce_count)
          else
            ((knife_count > 0) || (tsukudani_count > 0)) ? wrapping_model = "WrappingModel2" : wrapping_model = "WrappingModel1"
            new_sender_model[wrapping_model] = {
              "title" => 2,
              "name" => "Oyster38 オイスターソース#{('× ' + sauce_count.to_s) if (sauce_count > 1)}",
              "price" => (1500 * sauce_count),
              "taxRate" => 0.1,
              "includeTaxFlag" => 1,
              "deleteWrappingFlag" => 0
              }
          end
        end
        unless coupon_model.nil? || coupon_model.empty?
          new_sender_model["CouponModelList"]= order["CouponModelList"]
        end
        ap new_sender_model
        response = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderSender/",
          :headers => @auth_header,
          :body => new_sender_model.to_json)
        errors[:sender_model] = response.parsed_response unless response["MessageModelList"].first["messageType"] == "INFO"

        ## SET MEMO, SHIP DATE, MEMO(ERROR, PAYMENT METHOD, GIFT, COOL/FROZEN, COUNTS), AND UPDATE SUBSTATUS COMPLETE
        frozen_check = @packages.map{|pkg| pkg[:items_list].map{|item| item_frozen?(item[:id])}}.flatten.compact.include?(true)
        payment_method = order["SettlementModel"]["settlementMethod"]
        remarks = order["remarks"].delete("\n")[/(?<=\[メッセージ添付希望・他ご意見、ご要望がありましたらこちらまで:\]).*/]
        memo_product_names = @packages.map{|pkg| pkg[:items_list].map{|item| memo_product_name(item[:id]) + "#{('x' + item[:count].to_s) if item[:count].to_i > 1}" }}.flatten.join(' ')
        memo_date_memo = order["remarks"].delete("\n")[/(?<=\[配送日時指定:\]).*(?=\[メッセージ)/].sub(/[0-9]{4}-(1[0-2]|0[1-9])-(3[01]|[12][0-9]|0[1-9])/, '').sub(/\(.\)(午前中)/,'').sub(/\(.\)/,'').sub(/[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}/,'').sub('指定なし', '')
        has_noshi = !@packages.map{|pkg| pkg[:noshi] }.compact.empty?
        gift = !order["giftCheckFlag"].zero?
        there_are_errors = !errors.empty?
        additional_shipping = @packages.map{|pkg| pkg[:items_list].map{|item| item[:extra_delivery_cost]}.inject(0, :+) > 0 }.include?(true)
        days = @packages.map{|pkg| (@arrival_date - Date.parse(pkg[:shipping_date])).to_i }.max
        memo = "#{memo_product_names} #{' ソース同梱' if (sauce_count > 0)}#{' 佃煮同梱' if (tsukudani_count > 0)}#{' 時間指定無理' if @impossible_delivery_time}#{' 1月OK' if new_year_delivery}#{' ' + days.to_s + 'D' if days > 1}#{' 離島' if isolated_island }#{' 送料追加' if additional_shipping}#{' ナイフ' if knife_count > 0}#{' のし' if has_noshi}#{' 冷凍' if frozen_check}#{' ' + payment_method if (payment_method == "代金引換" || payment_method == "銀行振込")}#{' 前払' if payment_method.include?('前払')}#{' ギフト' if gift}#{' 備考あり' unless remarks.empty? }#{' 時間指定備考あり' unless memo_date_memo.empty?}#{' 自動処理エラー' if there_are_errors }#{ " #{end_of_year_memo}年内届" unless end_of_year_memo.empty?}"
        #same_sender = !order["equalSenderFlag"].zero?
        #several_sender = !order["severalSenderFlag"].zero?
        order_memo = {
          "orderNumber" => order_id,
          "subStatusId" => 15822,
          "deliveryClass" => (frozen_check ? 3 : 2),
          "deliveryDate" => (shipping_date_wait || includes_anago || new_year_delivery) ? nil : (end_of_year ? end_of_year : @arrival_date.to_s),
          "memo" => memo
        }
        ap order_memo
        # https://webservice.rms.rakuten.co.jp/merchant-portal/view?contents=/ja/common/1-1_service_index/rakutenpayorderapi/updateordermemo
        # response = HTTParty.post("https://api.rms.rakuten.co.jp/es/2.0/order/updateOrderMemo/",
        #   :headers => @auth_header,
        #   :body => order_memo.to_json)
        # errors[:order_memo] = response.parsed_response unless response["MessageModelList"].first["messageType"] == "INFO"
        # ap errors
      end
    ap 'Errors hash:'
    ap errors
    ap '--------------------------------------------------------------------'
    end; nil
  end

end
