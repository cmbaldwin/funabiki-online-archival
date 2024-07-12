class OnlineOrdersController < ApplicationController
  before_action :set_online_order, only: %i[ destroy ]

  def fetch_online_orders_list
    calendar_params[:date] ? @search_date = Date.parse(calendar_params[:date]) : @search_date = Time.zone.today
    @daily_orders = OnlineOrder.ship_search(@search_date)
    @new_online_orders = OnlineOrder.shinki

    start_date = calendar_params["start"] ? Date.strptime(calendar_params["start"]) : (Time.zone.today.at_beginning_of_month - 7.days)
    end_date = calendar_params["end"] ? Date.strptime(calendar_params["end"]) : (Time.zone.today.end_of_month + 7.days)
    @order_counts = Hash.new
    online_orders = OnlineOrder.where(ship_date: (start_date..end_date))
    online_orders.each do |order|
      @order_counts[order.ship_date].nil? ? @order_counts[order.ship_date] = 1 : @order_counts[order.ship_date] += 1
      (@order_counts[Time.zone.today].nil? ? @order_counts[Time.zone.today] = 1 : @order_counts[Time.zone.today] += 1) if order.ship_date.nil?
    end
    @holidays = japanese_holiday_background_events(start_date..end_date)
  end

  # GET /online_orders or /online_orders.json
  def index
    fetch_online_orders_list

  end

  def refresh
    WCAPI.new.update
    redirect_to action: "index"
  end

  def online_orders_shipping_list
    ship_date = online_order_generator_params[:ship_date]
    @filename = "FunabikiInfo 出荷表（#{ship_date}）.pdf"
    message = Message.new(user: current_user.id, model: 'online_orders_shipping_list', state: false, message: "Funabiki.info出荷表を作成中…", data: {ship_date: ship_date, filename: @filename, expiration: (DateTime.now + 1.day)})
    message.save
    OnlineOrdersShippingListWorker.perform_async(ship_date, message.id, @filename)
    head :ok
  end

  # DELETE /online_orders/1 or /online_orders/1.json
  def destroy
    @online_order.destroy
    respond_to do |format|
      format.html { redirect_to online_orders_url, notice: "Online order was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_online_order
      @online_order = OnlineOrder.find(params[:id])
    end

    def online_order_generator_params
      params.permit(:ship_date)
    end

    def calendar_params
      params.permit(:date, :start, :end, :_, :format)
    end

    # Only allow a list of trusted parameters through.
    def online_order_params
      params.require(:online_order).permit(:order_id, :status, :ship_date, :arrival_date, :order_date, :date_modified, :data)
    end
end
