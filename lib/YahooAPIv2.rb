class YahooAPIv2
  include HTTParty

  if ENV.fetch('YAHOO_PEM_FILE', nil) && ENV.fetch('YAHOO_PEM_PASS', nil) && Rails.env.production?
    pkcs12 File.read(Rails.root.join(ENV.fetch('YAHOO_PEM_FILE', nil))), ENV.fetch('YAHOO_PEM_PASS', nil)
  end

  @proxy = URI(ENV.fetch('QUOTAGUARDSTATIC_URL', nil))
  http_proxy @proxy.host, @proxy.port, @proxy.user, @proxy.password

  attr_accessor :user, :response, :request_type

  def initialize
    # We use the first user as a default because our first user is an admin
    @user = User.find(1)
    @user.data[:yahoo] ||= {}
    @seller_id = ENV.fetch('YAHOO_SELLER_ID', nil)
    @base_url = 'https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/'
    @response = ''
  end

  def authentication_data
    @user.data.dig(:yahoo)
  end

  def proxy?
    get('http://ip.jsontest.com').parsed_response != HTTParty.get('http://ip.jsontest.com').parsed_response
  end

  def login_code?
    @user.reload
    acquired = @user.data.dig(:yahoo, :login_token_code, :acquired)
    return false unless acquired

    acquired + 10.minutes > DateTime.now
  end

  def refresh_token?
    @user.reload
    return false unless @user.data.dig(:yahoo, :authorization, 'refresh_token')

    @user.data.dig(:yahoo, :authorization, :acquired) + 59.minutes > DateTime.now
  end

  def authorized?
    @user.reload
    acquisition_time = @user.data.dig(:yahoo, :authorization, :acquired)
    return false unless acquisition_time

    acquisition_time + 59.minutes > DateTime.now
  end

  def save_auth_token(response)
    # Share the token with all users
    User.yahoo_users.each do |user|
      user.data ||= {}
      user.data[:yahoo] ||= {}
      user.data[:yahoo][:authorization] = response
      user.data[:yahoo][:authorization][:acquired] = DateTime.now
      user.save
    end
    @user.reload
  end

  def login_code_token_request_body(code)
    {
      'code' => code,
      'grant_type' => 'authorization_code',
      'redirect_uri' => 'https://www.funabiki.online/yahoo/'
    }
  end

  def refresh_token_request_body
    {
      'grant_type' => 'refresh_token',
      'refresh_token' => @user.data.dig(:yahoo, :authorization, 'refresh_token')
    }
  end

  def auth_header
    encoded_auth = Base64.encode64("#{ENV.fetch('YAHOO_CLIENT_ID', nil)}:#{ENV.fetch('YAHOO_SECRET', nil)}").gsub("\n", '')
    {
      'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
      'Authorization' => "Basic #{encoded_auth}"
    }
  end

  def request_token(code = nil)
    request_body = code ? login_code_token_request_body(code) : refresh_token_request_body
    @response = self.class.post('https://auth.login.yahoo.co.jp/yconnect/v2/token', headers: auth_header,
                                                                                    body: request_body)
    if @response.parsed_response.include?('error')
      Rails.logger.error("Error requesting token: #{@response&.parsed_response}")
    else
      save_auth_token(@response.parsed_response)
    end
  end

  def dev?
    Rails.env.development?
  end

  def request_with_rescue(request_method, **params)
    ap "(This message only appears in development)\nSending #{request_method} with params:\n#{params}" if dev?
    (@response = nil)
    send(request_method, **params)
  rescue StandardError => e
    puts e && e.backtrace && @response
  end

  def acquire_auth_token
    # https://developer.yahoo.co.jp/yconnect/v1/server_app/explicit/token.html
    @request_type = nil
    @request_type = 'login_code' if login_code?
    @request_type = 'refresh_token' if refresh_token?
    return 'Error: No user data for acquiring auth token' unless @request_type

    request_with_rescue('request_token')
  end

  def endpoint_header
    {
      'Content-Type' => 'text/xml;charset=UTF-8',
      'Authorization' => "Bearer #{@user.data.dig(:yahoo, :authorization, 'access_token')}"
    }
  end

  def request_endpoint(**params)
    return Rails.logger.error('Unauthorized') unless authorized?

    @response = self.class.send(params[:get] ? 'get' : 'post',
                                "#{@base_url}#{params[:endpoint]}#{if params[:endpoint] == 'orderCount'
                                                                     "?sellerId=#{@seller_id}"
                                                                   end}",
                                headers: endpoint_header,
                                body: params[:body] || '')
  end

  def order_count
    # https://developer.yahoo.co.jp/webapi/shopping/orderCount.html
    request_with_rescue('request_endpoint', endpoint: 'orderCount', get: true)
  end

  def order_list_body(period)
    "<Req>
      <Search>
        <Result>2000</Result>
        <Condition>
          <OrderStatus>1,2,3,4,5</OrderStatus>
          <OrderTimeFrom>#{(DateTime.now - period).strftime('%Y%m%d')}000000</OrderTimeFrom>
          <OrderTimeTo>#{DateTime.now.strftime('%Y%m%d%H%M%S')}</OrderTimeTo>
        </Condition>
        <Field>OrderId</Field>
      </Search>
      <SellerId>oystersisters</SellerId>
    </Req>"
  end

  def order_list(period: 1.week)
    request_with_rescue('request_endpoint', endpoint: 'orderList', body: order_list_body(period))
  end

  def order_info_fields
    'OrderTime,OrderId,DeviceType,IsRoyalty,IsAffiliate,OrderStatus,StoreStatus,IsActive,IsSeen,IsSplit,Suspect,IsRoyaltyFix,PayStatus,SettleStatus,PayType,PayMethod,NeedBillSlip,NeedDetailedSlip,NeedReceipt,BillFirstName,BillFirstNameKana,BillLastName,BillLastNameKana,BillPrefecture,ShipFirstName,ShipFirstNameKana,ShipLastName,ShipLastNameKana,ShipPrefecture,ShipStatus,ShipMethod,ShipCompanyCode,IsLogin,TotalPrice,IsReadOnly,UsePointType,PayMethod,PayMethodName,BillZipCode,BillPrefecture,BillPrefectureKana,BillCity,BillCityKana,BillAddress1,BillAddress1Kana,BillAddress2,BillAddress2Kana,BillPhoneNumber,ShipMethod,ShipMethodName,ShipRequestDate,ShipRequestTime,ArriveType,ShipDate,ShipRequestTimeZoneCode,ShipZipCode,ShipPrefecture,ShipPrefectureKana,ShipCity,ShipCityKana,ShipAddress1,ShipAddress1Kana,ShipAddress2,ShipAddress2Kana,ShipPhoneNumber,ShipEmgPhoneNumber,ShipInvoiceNumber1,ShipInvoiceNumber2,ShipSection1Field,ShipSection1Value,ShipSection2Field,ShipSection2Value,ShipCharge,PayCharge,GiftWrapCharge,LineId,ItemId,Title,SubCode,SubCodeOption,ItemOption,ProductId,Quantity'
  end

  def order_info_body(order_id)
    "<Req>
      <Target>
        <OrderId>#{order_id}</OrderId>
        <Field>#{order_info_fields}</Field>
      </Target>
      <SellerId>oystersisters</SellerId>
    </Req>"
  end

  def order_info(order_id)
    request_with_rescue('request_endpoint', endpoint: 'orderInfo', body: order_info_body(order_id))
  end

  def save_order(order_id)
    order_info(order_id)
    return "Error: #{@resonse}" unless status_ok

    details = @response.parsed_response.dig('ResultSet', 'Result', 'OrderInfo')
    @order = YahooOrder.find_or_initialize_by(order_id: details['OrderId'])
    @order.details = details
    @order.order_time = DateTime.parse(details['OrderTime'])
    @order.order_status = details['OrderStatus']
    @order.shipping_status = details['Ship']['ShipStatus']
    ship_date = details.dig('Ship', 'ShipDate')
    @order.ship_date = ship_date if ship_date
    @order.save
  end

  def status_ok
    return false unless @response.is_a?(HTTParty::Response)

    res = @response.parsed_response
    res.dig('Result', 'Status') == 'OK' || res.dig('ResultSet', 'Result', 'Status') == 'OK'
  end

  def capture_orders(period: 1.week)
    order_list(period:)
    return "Error: #{@response}" unless status_ok

    results = @response.parsed_response.dig('Result', 'Search', 'OrderInfo')
    order_ids = results.is_a?(Array) ? results.map { |order| order['OrderId'] } : [results['OrderId']]
    order_ids.each { |order_id| save_order(order_id) }
  end

  def update_processing
    YahooOrder.processing.pluck(:order_id).each { |order_id| save_order(order_id) }
  end
end
