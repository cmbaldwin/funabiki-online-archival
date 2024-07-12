class YahooOrdersController < ApplicationController
  # GET /fetch_yahoo_list/fetch_daily_orders/:date
  # GET /fetch_yahoo_list/fetch_daily_orders.js
  def fetch_yahoo
    @search_date = yahoo_order_params[:date] ? Date.parse(yahoo_order_params[:date]) : Time.zone.today
    @daily_orders = YahooOrder.with_date(@search_date).order(:order_id)
    @daily_orders += YahooOrder.undated if @search_date == Time.zone.today

    start_date = yahoo_order_params['start'] ? Date.strptime(yahoo_order_params['start']) : (Time.zone.today.at_beginning_of_month - 7.days)
    end_date = yahoo_order_params['end'] ? Date.strptime(yahoo_order_params['end']) : (Time.zone.today.end_of_month + 7.days)
    @order_counts = {}
    yahoo_orders = YahooOrder.with_date(start_date..end_date)
    new_orders = YahooOrder.undated if @search_date == Time.zone.today
    yahoo_orders.each do |order|
      @order_counts[order.ship_date].nil? ? @order_counts[order.ship_date] = 1 : @order_counts[order.ship_date] += 1
    end
    new_orders&.each do |_order|
      if @order_counts[Time.zone.today].nil?
        @order_counts[Time.zone.today] =
          1
      else
        @order_counts[Time.zone.today] += 1
      end
    end
    @holidays = japanese_holiday_background_events(start_date..end_date)
  end

  def fetch_yahoo_list
    fetch_yahoo
    render turbo_stream: turbo_stream.replace('daily_orders', partial: 'daily_orders')
  end

  # GET /yahoo_orders
  # GET /yahoo_orders.sjson
  def index
    fetch_yahoo
  end

  def refresh
    uri = 'https://www.funabiki.online/yahoo/'
    @url = "https://auth.login.yahoo.co.jp/yconnect/v2/authorization?response_type=code&client_id=#{ENV.fetch('YAHOO_CLIENT_ID', nil)}&redirect_uri=#{uri}&scope=openid+profile+email"

    client = YahooAPIv2.new

    Rails.logger.info client.authorized?
    if client.authorized?
      message = Message.new(user: current_user.id, model: 'update_yahoo', state: false, message: 'ヤフー注文データを更新中…',
                            data: { user: current_user.id, expiration: (DateTime.now + 5.minute) })
      message.save
      YahooUpdateWorker.perform_async(message.id)
      head :ok
    else
      redirect_to @url, allow_other_host: true
    end
  end

  def yahoo_token_update
    auth_data = params['yahoo_auth']['data']['yahoo']['authorization']
    token_data = params['yahoo_auth']['data']['yahoo']['login_token_code']
    return unless auth_data

    current_user.data ||= {}
    current_user.data[:yahoo] ||= {}
    current_user.data[:yahoo][:authorization] ||= {}
    keys = %w[access_token expires_in id_token refresh_token token_type]

    keys.each do |key|
      current_user.data[:yahoo][:authorization][key] = auth_data[key.to_sym]
    end
    current_user.data[:yahoo][:authorization][:acquired] = DateTime.parse(auth_data['acquired'])
    # current_user.data[:yahoo][:login_token_code][:acquired] = DateTime.parse(token_data['acquired'])
    # current_user.data[:yahoo][:login_token_ode][:token_code] = DateTime.parse(token_data['token_code'])
    current_user.save
    redirect_to edit_user_registration_path
  end

  # example dev enviornment response URI /yahoo/?code=kk8vbp5r&state=1
  def yahoo_response_auth_code
    @code = yahoo_order_params[:code]
    if @code
      flash[:notice] = 'コード取得出来ました。ヤフーからデータを更新開始。'
      client = YahooAPIv2.new
      client.request_token(@code)
      redirect_to refresh_yahoo_path
    else
      flash[:notice] = @code + 'のトークンコードを保存できませんでした。アドミニストレータに連絡。'
      redirect_to yahoo_orders_path
    end
  end

  # GET /yahoo_spreadsheet/:ship_date
  def yahoo_spreadsheet
    require 'spreadsheet'

    ship_date = params[:ship_date]
    orders = YahooOrder.all.where(ship_date:)

    top_row = %w[送り状種類 クール区分 出荷予定日 お届け予定日 配達時間帯 お届け先電話番号 お届け先電話番号枝番 お届け先郵便番号 お届け先住所 お届け先アパートマンション名 お届け先会社・部門１
                 お届け先会社・部門２ お届け先名 お届け先名(ｶﾅ) 敬称 ご依頼主電話番号 ご依頼主郵便番号 ご依頼主住所 ご依頼主アパートマンション ご依頼主名 ご依頼主名(ｶﾅ) 品名コード１ 品名１ 品名コード２ 品名２ 荷扱い１ 荷扱い２ 記事 請求先顧客コード 運賃管理番号]

    book = Spreadsheet::Workbook.new
    book.create_worksheet name: 'ヤマトクロネコ外部データ'
    book.worksheet(0).insert_row(0, top_row)
    orders.each_with_index do |order, i|
      book.worksheet(0).insert_row((i + 1), order.yamato_shipping_format)
    end

    spreadsheet = StringIO.new
    book.write spreadsheet
    send_data spreadsheet.string, filename: "yahoo-oystersisters-#{ship_date}.xls",
                                  type: 'application/vnd.ms-excel'
  end

  # GET /yahoo_csv/:ship_date
  def yahoo_csv
    require 'spreadsheet'
    ship_date = params[:ship_date]
    orders = YahooOrder.all.where(ship_date:)
    shipping_csv = CSV.generate(row_sep: "\r\n", encoding: Encoding::SJIS, headers: true) do |csv|
      csv << %w[送り状種類 クール区分 出荷予定日 お届け予定日 配達時間帯 お届け先電話番号 お届け先電話番号枝番 お届け先郵便番号 お届け先住所 お届け先アパートマンション名 お届け先会社・部門１ お届け先会社・部門２
                お届け先名 お届け先名(ｶﾅ) 敬称 ご依頼主電話番号 ご依頼主郵便番号 ご依頼主住所 ご依頼主アパートマンション ご依頼主名 ご依頼主名(ｶﾅ) 品名コード１ 品名１ 品名コード２ 品名２ 荷扱い１ 荷扱い２ 記事 請求先顧客コード 運賃管理番号 コレクト代金引換額（税込）]
      orders.each do |order|
        csv << order.yamato_shipping_format
      end
    end
    respond_to do |format|
      format.csv do
        send_data shipping_csv, filename: "yahoo-oystersisters-#{ship_date}.csv", disposition: :attachment,
                                type: 'text/csv'
      end
    end
  end

  # GET /yahoo_shipping_list
  # GET /yahoo_shipping_list
  def yahoo_shipping_list
    @filename = "Yahoo-#{params[:ship_date]}-#{DateTime.now}.pdf"
    message = Message.new(user: current_user.id, model: 'yahoo_shipping_list', state: false, message: 'ヤフー出荷表を作成中…',
                          data: { ship_date: params[:ship_date], filename: @filename, expiration: (DateTime.now + 1.day) })
    message.save
    YahooShippingListWorker.perform_async(params[:ship_date], message.id, @filename)
    head :ok
  end

  # GET /yahoo_orders/1
  # GET /yahoo_orders/1.json
  def show; end

  private

  def yahoo_order_params
    params.permit(:start, :end, :code, :state, :format, :orders, :date, :_)
  end

  def yahoo_auth_params
    params.permit(yahoo_auth: {})
  end
end
