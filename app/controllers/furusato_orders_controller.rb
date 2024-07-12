class FurusatoOrdersController < ApplicationController
  before_action :fetch_furusato_orders_list, only: %i[index show]

  def fetch_furusato_orders_list
    @search_date = calendar_params[:date] ? Date.parse(calendar_params[:date]) : Time.zone.today
    @furusato_orders = FurusatoOrder.with_date(@search_date)
    start_date = calendar_params['start'] ? Date.strptime(calendar_params['start']) : (Time.zone.today.at_beginning_of_month - 7.days)
    end_date = calendar_params['end'] ? Date.strptime(calendar_params['end']) : (Time.zone.today.end_of_month + 7.days)
    @holidays = japanese_holiday_background_events(start_date..end_date)
    @order_counts = {}
    date_range = start_date..end_date
    range_orders = nil
    date_range.each do |date|
      range_orders.nil? ? range_orders = FurusatoOrder.with_date(date) : range_orders += FurusatoOrder.with_date(date)
    end
    range_orders.each do |order|
      order_ship_date = order.est_shipping_date
      if order_ship_date
        @order_counts[order_ship_date].nil? ? @order_counts[order_ship_date] = 1 : @order_counts[order_ship_date] += 1
      end
    end
  end

  # GET /furusato_orders or /furusato_orders.json
  def index; end

  def show; end

  def refresh
    BrowseBotAPI.get_furusato

    redirect_to furusato_orders_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def calendar_params
    params.permit(:date, :_, :start, :end, :format)
  end
end
