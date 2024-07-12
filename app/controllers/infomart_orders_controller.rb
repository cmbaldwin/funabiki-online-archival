class InfomartOrdersController < ApplicationController
  def fetch_infomart
    @search_date = calendar_params[:date] ? calendar_params[:date].to_date : Time.zone.today
    @daily_orders = InfomartOrder.where(ship_date: @search_date).order(:order_time)
    @daily_orders += InfomartOrder.where(ship_date: nil).order(:order_time) if @search_date == Time.zone.today

    start_date = calendar_params['start'] ? Date.strptime(calendar_params['start']) : (Time.zone.today.at_beginning_of_month - 7.days)
    end_date = calendar_params['end'] ? Date.strptime(calendar_params['end']) : (Time.zone.today.end_of_month + 7.days)
    infomart_orders = InfomartOrder.where(ship_date: (params[:start]..params[:end]))
    infomart_orders += InfomartOrder.where(ship_date: nil) if @search_date == Time.zone.today
    @order_counts = {}
    infomart_orders.each do |order|
      @order_counts[order.ship_date].nil? ? @order_counts[order.ship_date] = 1 : @order_counts[order.ship_date] += 1
      next unless order.ship_date.nil?

      (if @order_counts[Time.zone.today].nil?
         @order_counts[Time.zone.today] =
           1
       else
         @order_counts[Time.zone.today] += 1
       end)
    end
    @holidays = japanese_holiday_background_events(start_date..end_date)
  end

  def fetch_infomart_list
    fetch_infomart
    render turbo_stream: turbo_stream.replace('daily_orders', partial: 'daily_orders')
  end

  # GET /infomart_orders
  # GET /infomart_orders.json
  def index
    fetch_infomart
  end

  def refresh
    InfomartAPI.new.acquire_new_data
    redirect_to action: 'index'
  end

  def infomart_shipping_list
    ship_date = infomart_generator_params[:ship_date]
    @filename = "Infomart出荷表（#{ship_date}）.pdf"
    message = Message.new(user: current_user.id, model: 'infomart_shipping_list', state: false,
                          message: 'Infomart出荷表を作成中…', data:
                          {
                            ship_date:,
                            filename: @filename,
                            expiration: (DateTime.now + 1.day)
                          })
    message.save
    InfomartShippingListWorker.perform_async(ship_date, message.id, infomart_generator_params[:blank])
    head :ok
  end

  # GET /manifests/csv_upload
  def csv_upload
    require 'csv'
    require 'json'

    if params[:csv]
      # prepare to process
      existing_updated = Set.new
      newly_created = Set.new
      puts 'Processing data...'

      # process
      InfomartAPI.new.process_csv(params[:csv].tempfile, existing_updated, newly_created)
      puts "#{newly_created.length + existing_updated.length} Infomart order changes were made, #{newly_created.length} newly created and #{existing_updated.length} existing orders found and, if necessary, updated."
      FileUtils.rm_rf(params[:csv].tempfile)
      redirect_to infomart_orders_path(date: Time.zone.today)
    else
      redirect_to action: 'index'
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def infomart_generator_params
    params.permit(:ship_date, :blank)
  end

  def calendar_params
    params.permit(:date, :start, :end, :_, :format)
  end

  # Only allow a list of trusted parameters through.
  def infomart_order_params
    # For the timing being orders can only be modified through the InfomartAPI system, so no need to allow params here.
    # params.require(:infomart_order).permit(:order_id, :status, :order_time, :ship_date, :arrival_date, :address, items: {}, csv_data: {})
  end
end
