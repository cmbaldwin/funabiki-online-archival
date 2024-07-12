module Oroshi
  class SuppliesController < ApplicationController
    before_action :set_supply
    before_action :set_supply_dates, only: %i[index]

    # GET /oroshi/supplies
    # GET /oroshi/supplies.json
    def index; end

    # GET /oroshi/supplies/1
    def show; end

    # PATCH/PUT /oroshi/supplies/1
    def update
      @supply.update(supply_params)
      head :ok
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_supply
      id = params[:id] || params[:supply_id]
      @supply = id ? Oroshi::Supply.find(id) : Oroshi::Supply.new
    end

    def fetch_supply_range(start_date, end_date)
      offset = 14.days
      start_date = Date.strptime(start_date) if start_date
      start_date ||= Time.zone.today.at_beginning_of_month - offset
      end_date = Date.strptime(end_date) if end_date
      end_date ||= Time.zone.today.end_of_month + offset
      start_date..end_date
    end

    def set_supply_dates
      range = fetch_supply_range(calendar_params['start'], calendar_params['end'])
      @invoices = Oroshi::Invoice.where('start_date IN (?) OR end_date IN (?)', range, range)
      @supply_dates = Oroshi::SupplyDate.includes(:supply_date_supply_type_variations).where(date: range)
      @holidays = japanese_holiday_background_events(range)
    end

    def calendar_params
      params.permit(:place, :start, :end, :_, :format)
    end

    # Only allow a list of trusted parameters through.
    def supply_params
      params.require(:oroshi_supply)
            .permit(:supply_date_id, :supply_type_variation_id, :supply_reception_time_id,
                    :supplier_id, :quantity, :price)
    end

    def new_supply_params
      params.permit(:supply_date_id, :supplier_id, :supply_type_variation_id, :supply_reception_time_id, :index)
    end
  end
end
