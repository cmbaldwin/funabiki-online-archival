class YahooAPI
  include HTTParty
  # There are three required variables and two optional variables
  # ENV['YAHOO_PEM_FILE'] --PEM file name, located in the rails root directory
  # ENV['YAHOO_PEM_PASS'] --PEM file password (see: https://developer.yahoo.co.jp/webapi/shopping/help.html#orderapicertificate)
  # ENV["QUOTAGUARDSTATIC_URL"] --The URL of your proxy including user:password and port
  # ENV['YAHOO_CLIENT_ID'] --A Yahoo shopping API approved development client ID (requires application)
  # ENV['YAHOO_SECRET'] -- The above client's secret key

  # https://github.com/jnunemaker/httparty/blob/6f4d6ea4a2707a4f1466f45bf5c67556cdbed2b7/lib/httparty.rb#L322
  # if ENV['YAHOO_PEM_FILE'] && ENV['YAHOO_PEM_PASS']
  #   pkcs12 File.read(Rails.root.join("/#{ENV['YAHOO_PEM_FILE']}")), ENV['YAHOO_PEM_PASS']
  # end

  # See https://github.com/jnunemaker/httparty/blob/6f4d6ea4a2707a4f1466f45bf5c67556cdbed2b7/lib/httparty.rb#L29
  # If you haven't set this enviornment variable the client will return an error
  @proxy = URI(ENV['QUOTAGUARDSTATIC_URL'])
  http_proxy @proxy.host, @proxy.port, @proxy.user, @proxy.password

  def initialize(current_user = User.find(1))
    # We use the first user as a default because our first user is an admin
    @user = current_user
    @user.data[:yahoo] ||= {}
  end

  def auth_header
    encoded_auth = Base64.encode64("#{ENV['YAHOO_CLIENT_ID']}#{ENV['YAHOO_SECRET']}").gsub(/\n/, '')
    {
      'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
      'Authorization' => "Basic #{encoded_auth}"
    }
  end

  def proxy?
    self.class.get('http://ip.jsontest.com').parsed_response != HTTParty.get('http://ip.jsontest.com').parsed_response
  end

  def login_code?
    @user.reload
    if defined? @user.data[:yahoo][:login_token_code][:acquired]
      puts 'Login token code found.'
      if @user.data[:yahoo][:login_token_code][:acquired] + 10.minutes > DateTime.now
        puts 'Login token code not expired.'
        true
      else
        puts 'Login token code expired'
        false
      end
    else
      puts 'No login token code.'
      false
    end
  end

  def refresh_token?
    @user.reload
    if defined? @user.data[:yahoo][:authorization]['refresh_token']
      puts 'Authorization refresh token found.'
      if (@user.data[:yahoo][:authorization][:acquired] + 59.minutes) > DateTime.now
        puts 'Authorization refresh token not expired.'
        true
      else
        puts 'Authorization refresh token expired.'
        false
      end
    else
      puts 'No authorization refresh token availiable.'
      false
    end
  end

  def authorized?
    @user.reload
    if defined? @user.data[:yahoo][:authorization][:acquired]
      puts 'Authorized to access API.'
      true
    else
      false
    end
  end

  def save_auth_token(response)
    User.yahoo_users.each do |user|
      user.data[:yahoo][:authorization] = {}
      user.data[:yahoo][:authorization] = response
      user.data[:yahoo][:authorization][:acquired] = DateTime.now
      user.save
    end
    @user.reload
  end

  def acquire_auth_token(code = nil)
    # https://developer.yahoo.co.jp/yconnect/v1/server_app/explicit/token.html
    if code
      begin
        puts 'Acquiring authorization access token using temporary login token code'
        req_body = {
          'grant_type' => 'authorization_code',
          'code' => code,
          'redirect_uri' => 'https://www.funabiki.online/yahoo/'
        }
        request = self.class.post('https://auth.login.yahoo.co.jp/yconnect/v2/token', headers: auth_header,
                                                                                      body: req_body)
        puts 'Success, Authorization Token Saved.' if save_auth_token(request.parsed_response)
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap request
      end
    elsif refresh_token?
      begin
        puts 'Refreshing authorization access token'
        req_body = {
          'grant_type' => 'refresh_token',
          'refresh_token' => @user.data[:yahoo][:authorization]['refresh_token']
        }
        request = self.class.post('https://auth.login.yahoo.co.jp/yconnect/v2/token', headers: auth_header,
                                                                                      body: req_body)
        save_auth_token(request.parsed_response)
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap request
      end
    else
      puts 'No login code or refresh token.'
    end
  end

  def order_info_fields
    'OrderTime,OrderId,DeviceType,IsRoyalty,IsAffiliate,OrderStatus,StoreStatus,IsActive,IsSeen,IsSplit,Suspect,IsRoyaltyFix,PayStatus,SettleStatus,PayType,PayMethod,NeedBillSlip,NeedDetailedSlip,NeedReceipt,BillFirstName,BillFirstNameKana,BillLastName,BillLastNameKana,BillPrefecture,ShipFirstName,ShipFirstNameKana,ShipLastName,ShipLastNameKana,ShipPrefecture,ShipStatus,ShipMethod,ShipCompanyCode,IsLogin,TotalPrice,IsReadOnly,UsePointType,PayMethod,PayMethodName,BillZipCode,BillPrefecture,BillPrefectureKana,BillCity,BillCityKana,BillAddress1,BillAddress1Kana,BillAddress2,BillAddress2Kana,BillPhoneNumber,ShipMethod,ShipMethodName,ShipRequestDate,ShipRequestTime,ArriveType,ShipDate,ShipRequestTimeZoneCode,ShipZipCode,ShipPrefecture,ShipPrefectureKana,ShipCity,ShipCityKana,ShipAddress1,ShipAddress1Kana,ShipAddress2,ShipAddress2Kana,ShipPhoneNumber,ShipEmgPhoneNumber,ShipInvoiceNumber1,ShipInvoiceNumber2,ShipSection1Field,ShipSection1Value,ShipSection2Field,ShipSection2Value,ShipCharge,PayCharge,GiftWrapCharge,LineId,ItemId,Title,SubCode,SubCodeOption,ItemOption,ProductId,Quantity'
  end

  def get_status(acquire_new_details, message_id = nil)
    # https://developer.yahoo.co.jp/webapi/shopping/orderCount.html
    if authorized?
      begin
        request = self.class.get('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderCount?sellerId=oystersisters',
                                 headers: {
                                   'Content-Type' => 'text/xml;charset=UTF-8',
                                   'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token']
                                 })
        @user.data[:yahoo] = {} if @user.data[:yahoo].nil?
        @user.data[:yahoo][:store_status] = {}
        @user.data[:yahoo][:store_status][:status] = request.parsed_response
        @user.data[:yahoo][:store_status][:acquired] = DateTime.now
        @user.save
        if message_id
          message = Message.find(message_id)
          message.update(message: "ヤフー注文データ取込み中。注文データ:
            新規: #{request.parsed_response['ResultSet']['Result']['Count']['NewOrder'].to_i if request.parsed_response.dig(
              'ResultSet', 'Result', 'Count', 'NewOrder'
            )}
            処理/出荷: #{request.parsed_response['ResultSet']['Result']['Count']['Shipping'].to_i if request.parsed_response.dig(
              'ResultSet', 'Result', 'Count', 'Shipping'
            )}
            保留: #{request.parsed_response['ResultSet']['Result']['Count']['Holding'].to_i if request.parsed_response.dig(
              'ResultSet', 'Result', 'Count', 'Holding'
            )}
            自動完了: #{request.parsed_response['ResultSet']['Result']['Count']['AutoDone'].to_i if request.parsed_response.dig(
              'ResultSet', 'Result', 'Count', 'AutoDone'
            )}")
        end
        if acquire_new_details
          # Old extremely lazy method
          stop_after = 5 # base of 5 checks for temporary error correction
          stop_after += request.parsed_response['ResultSet']['Result']['Count']['NewOrder'].to_i if request.parsed_response.dig(
            'ResultSet', 'Result', 'Count', 'NewOrder'
          )
          stop_after += request.parsed_response['ResultSet']['Result']['Count']['AutoDone'].to_i if request.parsed_response.dig(
            'ResultSet', 'Result', 'Count', 'AutoDone'
          )
          stop_after += request.parsed_response['ResultSet']['Result']['Count']['Shipping'].to_i if request.parsed_response.dig(
            'ResultSet', 'Result', 'Count', 'AutoDone'
          )
          stop_after > 0 ? get_order_details_in_sequence(stop_after, message_id) : (ap request.parsed_response)
          # order_ids = new_orders_id_list
          # #existing = YahooOrder.where(order_id: order_ids).pluck(:order_id)
          # #new_order_ids = order_ids - existing
          # order_ids.each{|order_id| refresh_single_order_details(order_id) }
        end
        true
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap request if request
        false
      end
    else
      puts 'No authorization, login required.'
      false
    end
  end

  # Used for testing. You'll need to copy an autho code from the app to the local dev enviornment to use this...
  def new_orders_id_list(period = 1.week)
    return unless authorized?

    begin
      request = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderList',
                                headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                           'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                body: "<Req>
              <Search>
                <Condition>
                  <OrderStatus>1,2,3,4,5</OrderStatus>
                  <OrderTimeFrom>" + (DateTime.now - period).strftime('%Y%m%d') + '000000' + "</OrderTimeFrom>
                  <OrderTimeTo>" + DateTime.now.strftime('%Y%m%d%H%M%S') + "</OrderTimeTo>
                </Condition>
                <Field>OrderId</Field>
              </Search>
              <SellerId>oystersisters</SellerId>
            </Req>").parsed_response
      if request.dig('Result', 'Status') == 'OK'
        request['Result']['Search']['OrderInfo'].map { |o| o['OrderId'] }

      else
        ap 'error'
        ap request
      end
    rescue StandardError => e
      puts 'Error:'
      ap e
      ap e.backtrace
    end
  end

  def process_order(order_id)
    # https://developer.yahoo.co.jp/webapi/shopping/orderChange.html
    # orders = YahooOrder.find([564, 560, 539]) <= option added orders
    # orders = YahooOrder.find([246,142,361,406,409]) <= extra shipping orders
    order = YahooOrder.find_by(order_id:)
    return unless order.store_status.nil? # All new orders have no store status.

    if authorized?

      memo = ''
      ship_notes = ''
      invoice_number = ''
      ship_date = ''
      arrival_date = ''

      begin
        order_change = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderChange',
                                       headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                                  'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                       body: "<Req>
                <Target>
                  <OrderId>#{order.order_id}</OrderId>
                  <SellerId>oystersisters</SellerId>
                </Target>
                <Order>
                  <StoreStatus>1</StoreStatus>
                  <Notes>#{memo}</Notes>
                  <Ship>
                    <ShipNotes></ShipNotes>
                    <ShipCompanyCode>1001</ShipCompanyCode>
                    <ShipInvoiceNumber1>#{invoice_number}</ShipInvoiceNumber1>
                    <ShipDate>#{ship_date}</ShipDate>
                    <ArrivalDate>#{arrival_date}</ArrivalDate>
                  </Ship>
                </Order>
              </Req>").parsed_response
        ap order_change
        true if order_change['Result']['Status'] == 'OK'
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap order_details if order_details
        false
      end
    else
      puts 'No authorization, login required.'
      false
    end
  end

  def get_new_orders(period = 2.weeks)
    # https://developer.yahoo.co.jp/webapi/shopping/orderList.html
    if authorized?
      begin
        request = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderList',
                                  headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                             'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                  body: "<Req>
              <Search>
                <Condition>
                <OrderStatus>1,2,3,4,5</OrderStatus>
                <OrderTimeFrom>" + (DateTime.now - period).strftime('%Y%m%d') + '000000' + "</OrderTimeFrom>
                <OrderTimeTo>" + DateTime.now.strftime('%Y%m%d%H%M%S') + "</OrderTimeTo>
                </Condition>
                <Field>OrderId,OrderStatus</Field>
              </Search>
              <SellerId>oystersisters</SellerId>
            </Req>")
        # ap request
        begin
          order_count = request.parsed_response['Result']['Search']['TotalCount']
        rescue StandardError
          ap request
          order_count = '0'
        end
        response = request.parsed_response['Result']['Search']['OrderInfo']
        if order_count.to_i == 0
          puts 'No new orders.'
          true
        else
          order_ids = []
          if response[0].is_a?(Hash)
            response.each_with_index do |order_response, _i|
              order_ids << order_response['OrderId']
            end
          else
            order_ids[0] = response['OrderId']
          end
          puts 'Getting order item details and recording orders in the database.'
          if order_ids
            get_order_details(order_ids)
            puts "Imported #{order_count} orders."
            true
          else
            puts 'Error with acquiring order item details.'
            false
          end
        end
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap request.parsed_response if request
        false
      end
    else
      puts 'No authorization, login required.'
      false
    end
  end

  def refresh_single_order_details(order_id)
    # https://developer.yahoo.co.jp/webapi/shopping/orderInfo.html
    if authorized?
      begin
        order_details = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderInfo',
                                        headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                                   'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                        body: "<Req>
              <Target>
                <OrderId>#{order_id}</OrderId>
                <Field>#{order_info_fields}</Field>
                </Target>
              <SellerId>oystersisters</SellerId>
            </Req>").parsed_response
        if order_details.dig('ResultSet', 'Result', 'Status') == 'OK'
          @order = YahooOrder.find_or_initialize_by(order_id:)
          ship_date = order_details['ResultSet']['Result']['OrderInfo']['Ship']['ShipDate']
          @order.ship_date = ship_date unless ship_date.nil?
          new_details = order_details.dig('ResultSet', 'Result', 'OrderInfo')
          @order.details = new_details if new_details
          @order.save
          true
        end
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap order_details if order_details
        false
      end
    else
      puts 'No authorization, login required.'
      false
    end
  end

  def get_order_details(order_id_array)
    # https://developer.yahoo.co.jp/webapi/shopping/orderInfo.html
    if authorized?
      begin
        all_order_details = {}
        order_id_array.each do |order_id|
          order_details = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderInfo',
                                          headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                                     'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                          body: "<Req>
                <Target>
                  <OrderId>#{order_id}</OrderId>
                  <Field>#{order_info_fields}</Field>
                  </Target>
                <SellerId>oystersisters</SellerId>
              </Req>").parsed_response
          if order_details['Error']
            ap order_details
          elsif order_details['ResultSet']['Result']['Status'] == 'OK'
            all_order_details[order_id] =
              order_details['ResultSet']['Result']['OrderInfo']
          end
        end
        record_sequenced_details(all_order_details) unless all_order_details.empty?
        true
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap request if request
        false
      end
    else
      puts 'No authorization, login required.'
      false
    end
  end

  def get_order_details_in_sequence(stop_after, message_id = nil)
    last_order_number = YahooOrder.all.order(:order_id).last.order_id[/\d+/].to_i
    sequence = stop_after.times.map { |t| 'oystersisters-' + (last_order_number + t).to_s }
    if authorized?
      begin
        all_order_details = {}
        sequence.each do |order_id|
          puts "Checking #{order_id}..."
          order_details = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderInfo',
                                          headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                                     'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                          body: "<Req>
                <Target>
                  <OrderId>#{order_id}</OrderId>
                  <Field>#{order_info_fields}</Field>
                  </Target>
                <SellerId>oystersisters</SellerId>
              </Req>").parsed_response
          # Example for no results
          # {"Error"=>{"Code"=>"od91801", "Message"=>"Not Exists : oystersisters-10000050", "Detail"=>nil}}
          if order_details['Error']
            if order_details['Error']['Code'] == 'od91801'
              puts "Order with ID #{order_id} does not exist."
            else
              ap order_details
            end
          elsif order_details['ResultSet']['Result']['Status'] == 'OK'
            all_order_details[order_id] =
              order_details['ResultSet']['Result']['OrderInfo']
          end
        end
        unless all_order_details.empty?
          record_sequenced_details(all_order_details)
          message = Message.find(message_id) if message_id
          message&.update(message: '処理中...')
        end
        true
      rescue TypeError
        puts 'Error with Yahoo API request:'
        ap order_details if order_details
        false
      end
    else
      puts 'No authorization, login required.'
      false
    end
  end

  def record_sequenced_details(sequenced_details)
    sequenced_details.each do |order_id, order_details|
      @order = if YahooOrder.exists?(order_id:)
                 YahooOrder.find_by(order_id:)
               else
                 YahooOrder.create(order_id:)
               end
      next if order_details.nil?

      @order.details = order_details
      @order.order_status = order_details['OrderStatus']
      @order.shipping_status = order_details['Ship']['ShipStatus']
      ship_date = order_details['Ship']['ShipDate'] unless order_details.dig('Ship', 'ShipDate').nil?
      @order.ship_date = ship_date unless ship_date.nil?
      @order.order_time = DateTime.parase(order_details['OrderTime'])
      @order.save
    end
  end

  def update_existing(period)
    return unless authorized?

    begin
      all_order_details = {}
      incomplete_orders = YahooOrder.where(ship_date: nil).order(:order_id).map do |order|
        order[:order_id] unless order.order_status(false) == 4
      end.compact
      period_orders = YahooOrder.where(created_at: [(Time.zone.today - period)..(Time.zone.today)]).pluck(:order_id)
      (incomplete_orders + period_orders).uniq.each do |order_id|
        order_details = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderInfo',
                                        headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                                   'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                        body: "<Req>
                <Target>
                  <OrderId>#{order_id}</OrderId>
                  <Field>#{order_info_fields}</Field>
                  </Target>
                <SellerId>oystersisters</SellerId>
              </Req>").parsed_response
        if order_details['Error']
          ap order_details
        else
          if order_details['ResultSet']['Result']['Status'] == 'OK'
            all_order_details[order_id] =
              order_details['ResultSet']['Result']['OrderInfo']
          end
          record_sequenced_details(all_order_details) unless all_order_details.empty?
        end
      end
    rescue TypeError
      puts 'Error with Yahoo API request:'
      ap request.parsed_response if request
      false
    end
  end

  def update_processing(message_id = nil)
    return unless authorized?

    begin
      Message.find(message_id).update(message: '処理中...') if message_id
      all_order_details = {}
      YahooOrder.processing.pluck(:order_id).each do |order_id|
        order_details = self.class.post('https://circus.shopping.yahooapis.jp/ShoppingWebService/V1/orderInfo',
                                        headers: { 'Content-Type' => 'text/xml;charset=UTF-8',
                                                   'Authorization' => 'Bearer ' + @user.data[:yahoo][:authorization]['access_token'] },
                                        body: "<Req>
                <Target>
                  <OrderId>#{order_id}</OrderId>
                  <Field>#{order_info_fields}</Field>
                  </Target>
                <SellerId>oystersisters</SellerId>
              </Req>").parsed_response
        if order_details['Error']
          ap order_details
        else
          if order_details['ResultSet']['Result']['Status'] == 'OK'
            all_order_details[order_id] =
              order_details['ResultSet']['Result']['OrderInfo']
          end
          record_sequenced_details(all_order_details) unless all_order_details.empty?
        end
      end
    rescue TypeError
      puts 'Error with Yahoo API request:'
      ap request.parsed_response if request
      false
    end
  end
end
