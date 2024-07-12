class FunabikiOrdersController < ApplicationController
  before_action :orders_list_setup, only: %i[index fetch_funabiki_list]

  def orders_list_setup
    @search_date ||= fetch_list_params[:date] ? Date.parse(fetch_list_params[:date]) : Time.zone.today
    @daily_orders = FunabikiOrder.with_date(@search_date)
  end

  # GET /funabiki_orders
  # GET /funabiki_orders.json
  def index
    @search_date = Date.parse(index_params[:date]) if index_params[:date]
    calendar_orders
  end

  def calendar_orders
    start_date = calendar_params['start'] ? Date.strptime(calendar_params['start']) : (Time.zone.today.at_beginning_of_month - 7.days)
    end_date = calendar_params['end'] ? Date.strptime(calendar_params['end']) : (Time.zone.today.end_of_month + 7.days)
    date_range = start_date..end_date
    @holidays = japanese_holiday_background_events(date_range)
    @order_counts = FunabikiOrder.with_dates(date_range).group(:ship_date).count
  end

  def fetch_funabiki_list
    render turbo_stream: turbo_stream.replace('daily_orders', partial: 'daily_orders')
  end

  def refresh
    message = Message.new(user: current_user.id,
                          model: 'refresh_funabiki',
                          state: false,
                          message: 'Funabiki.info注文データを更新中…',
                          data: { user: current_user.id, expiration: (DateTime.now + 2.minutes) })
    message.save
    SolidusApiWorker.perform_async(message.id)
    head :ok
  end

  def shipping_list
    message = Message.new(user: current_user.id,
                          model: 'funabiki_shipping_list',
                          state: false,
                          message: 'Funabiki.info出荷表を作成中…',
                          data: { ship_date: shipping_list_params[:date],
                                  expiration: (DateTime.now + 5.minutes) })
    message.save
    FunabikiShippingListWorker.perform_async(shipping_list_params[:date], message.id)
    head :ok
  end

  private

  def index_params
    params.permit(:date, :_, :format)
  end

  def calendar_params
    params.permit(:place, :start, :end, :_, :format)
  end

  def shipping_list_params
    params.permit(:date, :_, :format)
  end

  def fetch_list_params
    params.permit(:date, :_, :start, :end, :format)
  end
end
