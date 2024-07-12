class RakutenOrdersController < ApplicationController
  before_action :fetch_rakuten_orders, only: %i[index show fetch_rakuten_orders_list]

  def fetch_rakuten_orders
    @search_date = fetch_list_params[:date] ? Date.parse(fetch_list_params[:date]) : Time.zone.today
    @daily_orders = RakutenOrder.with_date(@search_date).order(:order_time).reverse
    @daily_orders += RakutenOrder.where(ship_date: []).order(:order_time).reverse if @search_date == Time.zone.today
  end

  def calendar_orders
    start_date = calendar_params['start'] ? Date.strptime(calendar_params['start']) : (Time.zone.today.at_beginning_of_month - 7.days)
    end_date = calendar_params['end'] ? Date.strptime(calendar_params['end']) : (Time.zone.today.end_of_month + 7.days)
    date_range = start_date..end_date
    @holidays = japanese_holiday_background_events(date_range)
    @order_counts = RakutenOrder.with_dates(date_range).group("unnest(ship_dates)").count
  end

  # GET /rakuten_orders or /rakuten_orders.json
  def index
    calendar_orders
  end

  def fetch_rakuten_orders_list
    render turbo_stream: turbo_stream.replace('daily_orders', partial: 'daily_orders')
  end

  # Automated remote processing of order details
  def jidou_syori
    message = Message.new(user: current_user.id, model: 'rakuten_process', state: false, message: '楽天自動処理中',
                          data: { expiration: (DateTime.now + 1.minute) })
    message.save
    RakutenProcessWorker.perform_async(message.id)
    head :ok
  end

  def refresh_month
    message = Message.new(user: current_user.id, model: 'rakuten_refresh', state: false, message: '楽天ーヶ月のデータを更新中',
                          data: { expiration: (DateTime.now + 1.minute) })
    message.save
    RakutenBigRefreshWorker.perform_async(message.id)
    head :ok
  end

  def refresh
    date = params[:date].nil? ? Time.zone.today : Date.parse(params[:date])
    message = Message.new(user: current_user.id, model: 'rakuten_refresh', state: false, message: '楽天データ更新中',
                          data: { expiration: (DateTime.now + 1.minute) })
    message.save
    RakutenRefreshWorker.perform_async(date, message.id)
    head :ok
  end

  def shipping_list
    seperated = params[:seperated] == '1'
    include_tsuhan = params[:include_tsuhan] == '1'
    @filename = "楽天#{'とヤフー' if include_tsuhan}#{' 商品分別版 ' if seperated}出荷表（#{params[:date]}）.pdf"
    message = Message.new(user: current_user.id, model: 'rakuten_manifest', state: false,
                          message: "楽天出荷表#{'とヤフー' if include_tsuhan}#{' 商品分別版 ' if seperated}を作成中…",
                          data: { search_date: params[:date],
                                  seperated:,
                                  include_tsuhan:,
                                  filename: @filename,
                                  expiration: (DateTime.now + 2.hours) })
    message.save
    RakutenManifestWorker.perform_async(params[:date], seperated, message.id, include_tsuhan)
    head :ok
  end

  def rakuten_shinki
    rakuten_api_client = RakutenAPI.new
    @rakuten_shinki = rakuten_api_client.get_details_by_ids(rakuten_api_client.get_shinki_without_shipdate_ids)
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def fetch_list_params
    params.permit(:date, :_, :start, :end, :format)
  end

  def calendar_params
    params.permit(:date, :place, :start, :end, :_, :format)
  end

  # Only allow a list of trusted parameters through.
  def rakuten_order_params
    params.require(:rakuten_order).permit(:order_id, :order_time, :ship_date, :arrival_date, :data, :date)
  end
end
