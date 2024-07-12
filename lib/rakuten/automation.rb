module Rakuten
  module Automation
    include Rakuten::Automation::DateSettings
    include Rakuten::Automation::ShippingModification
    include Rakuten::Automation::SenderModification
    include Rakuten::Automation::MemoModification

    def automate(orders: nil, debug: true)
      orders ||= unprocessed_order_details
      process(orders, debug:)
    end

    def unprocessed_order_details(date: Time.zone.today, period: 1.week)
      order_ids = unprocessed_order_ids(date:, period:)
      order_details(order_ids)
    end

    def unprocessed_order_ids(date: Time.zone.today, period: 1.week)
      search(date - period + 1.day, period, status: [100])
    end

    def unprocessed_orders_without_shipdates(finish_date = Time.zone.today, period_back = 7.days)
      order_ids = search((finish_date - period_back), period_back, status: [100, 200, 300, 400])
      order_details(order_ids)
    end

    def process(orders, debug: false, skip: true)
      @debug = debug
      @errors = {}
      orders.each do |order|
        @order = order
        next if skip_order? && skip

        @id = @order["orderNumber"]
        @arrival_date = @order["deliveryDate"]
        modify_packages # in ShippingModification
        post_update(:order_sender, 'updateOrderSender', new_order_sender)
        post_update(:order_shipping, 'updateOrderShipping', new_order_shipping)
        post_update(:order_memo, 'updateOrderMemo', new_order_memo)
      end
      @errors
    end

    def rakuten_processing_settings
      Setting.find_by(name: 'rakuten_processing_settings')
    end

    def get_setting(setting_name)
      rakuten_processing_settings&.settings&.dig(setting_name)
    end

    private

    def skip_order?
      # Preview processing of all orders if debugging
      ap(@order) if @debug
      return false if @debug

      # Only orders not already processed or sent to Rakuten for confirmation
      # Order Progress 100 is "注文確認待ち"
      # Sub Status 15822 is custom status for our Api, indicating processing attempted
      @order["orderProgress"] != 100 || @order["subStatusId"] == 15822 || skip_order_items?
    end

    def skip_order_items?
      # Items set in settings which, when present in an order, will cause the order to be skipped
      @skip_order_items ||= get_setting('skip_order_items') || []
      @skip_order_items.any? { |item| order_item_list.include?(item) }
    end

    def post_update(type, path, body)
      return ap [type, body] if @debug # remove 'return' to debug & post (to see live Rakuten API error responses)

      response = post("/order/#{path}/", body: body.to_json)
      return unless response["MessageModelList"].first["messageType"] == "ERROR"

      record_error(type, body, response.parsed_response)
    end

    def record_error(type, post, response)
      @errors[@id] ||= {}
      @errors[@id][:details] ||= @order
      @errors[@id][type] ||= {}
      @errors[@id][type][:post] = post
      @errors[@id][type][:response] = response
    end
  end
end
