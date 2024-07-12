module Rakuten
  module Orders
    # RakutenPayOrderAPI
    # https://webservice.rms.rakuten.co.jp/merchant-portal/view/ja/common/1-1_service_index/rakutenpayorderapi/

    def refresh(date: Time.zone.today, period: 1.week)
      @saved = 0
      @errors = []
      response_ids = search(date, period)
      order_ids = Set.new(RakutenOrder.with_dates((date - period)..(date + period)).find_each.map(&:order_id))
      order_ids.merge(response_ids)

      return 'No orders to refresh' if order_ids.blank?

      save(order_details(order_ids.to_a))
    end

    def get_recent_details(period: 2.weeks)
      order_details(search(Time.zone.today - period, period))
    end

    def search(date, period, status: [])
      start_date_time = jsonify_date(date - period)
      end_date_time = jsonify_date(date + period - 1.seconds)

      response = order_search(start_date_time, end_date_time, status:).parsed_response
      pages = response["PaginationResponseModel"]["totalPages"] || 1 # Set to 1 if 0 results returned, totalPages is nil
      order_ids = response["orderNumberList"]
      return order_ids unless pages > 1

      (2..pages).each do |page|
        order_ids.concat(order_search(start_date_time, end_date_time, status:, page: page).parsed_response["orderNumberList"])
      end
      order_ids
    rescue StandardError => e
      ap ['Error during search', e, e.backtrace, response]
    end

    def order_details(order_ids, version: 7)
      # API Response Versioning
      # 3: 消費税増税対応
      # 4: 共通の送料込みライン対応
      # 5: 領収書、前払い期限版
      # 6: 顧客・配送対応注意表示詳細対応
      # 7: SKU対応
      order_ids.each_slice(100).reduce([]) do |details, ids|
        response = post('/order/getOrder/',
                        { body: {
                          "orderNumberList" => ids,
                          "version" => version
                        }.to_json }).parsed_response
        messages = response["MessageModelList"]
        return response if order_detail_error(ids, messages)

        details << response["OrderModelList"]
      end.flatten
    end

    def order_detail_error(ids, messages)
      return false unless !messages.empty? && messages.to_s.include?("ERROR")

      puts "Order detail error from API: #{messages}, Concerned ids: #{ids}"
      true
    end

    def save(orders)
      @saved ||= 0
      @errors ||= []
      orders.each do |order_json|
        save_order(order_json)
        @saved += 1
      rescue StandardError => e
        @errors << [order_json["orderNumber"], e]
        puts ['Processing error during save', order_json["orderNumber"], e, e.backtrace]
      end
      [@saved, @errors]
    end

    def save_order(order_json)
      order = RakutenOrder.find_by(order_id: order_json["orderNumber"])
      order ||= RakutenOrder.new(order_id: order_json["orderNumber"])
      order.order_time = DateTime.parse(order_json["orderDatetime"])
      order.arrival_date = check_and_parse_date(order_json["deliveryDate"])
      order.ship_dates = shipping_dates(order_json)
      order.status = order_json["orderProgress"]
      order.data = order_json
      order.save
    end

    def check_and_parse_date(date_el)
      date_el&.then { |date| Date.parse(date) }
    end

    def shipping_dates(order_json)
      order_json["PackageModelList"].flat_map { |pkg| pkg["ShippingModelList"].map { |ship| check_and_parse_date(ship["shippingDate"]) } }.uniq
    end

    private

    def order_search(start_time, end_time, status: [], page: 1, records: 1000)
      # orderProgressList, List <Number>	128,以下のいずれか
      # 100: 注文確認待ち
      # 200: 楽天処理中
      # 300: 発送待ち
      # 400: 変更確定待ち
      # 500: 発送済
      # 600: 支払手続き中
      # 700: 支払手続き済
      # 800: キャンセル確定待ち
      # 900: キャンセル確定
      post('/order/searchOrder/',
           { body: {
             "orderProgressList" => status,
             "dateType" => 1,
             "startDatetime" => start_time,
             "endDatetime" => end_time,
             "PaginationRequestModel" => {
               "requestRecordsAmount" => records,
               "requestPage" => page,
               "SortModelList" => [{
                 "sortColumn" => 1,
                 "sortDirection" => 1
               }]
             }
           }.to_json })
    end
  end
end
