# rubocop: disable all

class ProfitsController < ApplicationController
  before_action :set_profit, only: %i[show edit update destroy autosave update_completion index_profit]
  before_action :check_status
  before_action :check_subtotals, only: [:show]
  before_action :set_types_markets_products, only: %i[new edit]

  def check_status
    return if current_user.admin?

    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  def check_subtotals
    return unless @profit.subtotals.nil?

    @profit.subtotals = @profit.calc_subtotals
    @profit.save
  end

  def set_types_markets_products
    @products = Product.order('namae DESC').all.includes(:markets)
    @markets = Market.order('mjsnumber').all
    @types = Rails.cache.fetch('types_set') do
      types_set = Set.new
      @products.each do |product|
        types_set.add(product.product_type)
      end
      types_set
    end
    @types_with_markets = Rails.cache.fetch('types_with_markets_hash') do
      types_with_markets_hash = {}
      i = 0
      @types.each do |t|
        market_types = Set.new
        types_with_markets_hash[t] = []
        @markets.each do |m|
          m.products.each do |k|
            market_types.add(k.product_type)
          end
          market_types.each do |mt|
            types_with_markets_hash[t] << m.namae if t == mt
          end
        end
        i += 1
      end
      types_with_markets_hash
    end
    @types_hash = Rails.cache.fetch('types_hash') do
      { '1' => 'トレイ', '2' => 'チューブ', '3' => '水切り', '4' => '殻付き', '5' => '冷凍', '6' => '単品' }
    end
  end

  def calendar_profits
    start_date = calendar_params['start'] ? Date.parse(calendar_params['start']) : (Time.zone.today.at_beginning_of_month - 7.days)
    end_date = calendar_params['end'] ? Date.parse(calendar_params['end']) : (Time.zone.today.end_of_month + 7.days)
    @calendar_profits = Profit.with_date(start_date..end_date)
    @holidays = japanese_holiday_background_events(start_date..end_date)
  end

  # GET /profits
  # GET /profits.json
  def index
    calendar_profits
    @profits = Profit.order(sales_date: :desc, ampm: :asc).paginate(page: params[:page], per_page: 14)
    @profit = @profits.first
  end

  def index_profit
    if @profit.subtotals.nil? || @profit.volumes.nil?
      @profit.assign_subtotals
      @profit.calculate_volumes
      @profit.save
    end

    render partial: 'profits/index/profit', locals: { profit: @profit }
  end

  # GET /profits/1
  # GET /profits/1.json
  def show
    @profit.products.select(:id, :grams, :count, :multiplier, :namae, :cost,
                            :average_price).as_json.each do |product_array|
      @product_data = {} if @product_data.nil?
      @product_data[product_array['id']] = product_array
    end
    @profit.markets.select(:id, :namae, :nick, :color, :handling, :brokerage, :cost,
                           :block_cost).as_json.each do |market_array|
      @market_data = {} if @market_data.nil?
      @market_data[market_array['id']] = market_array
    end
  end

  def first_market
    @market = Rails.cache.fetch('first_market', expires_in: 1.day) do
      Market.order('mjsnumber').first
    end
  end

  # GET /profits/new
  def new
    first_market
    @profit = Profit.new(profit_params)
  end

  def new_tabs
    first_market
    @profit = Profit.new
  end

  def next_market
    @profit = Profit.find(params[:id])
    last_market = params[:mjsnumber]
    unfinished = @profit.check_completion
    if unfinished[0].zero?
      first_market
    else
      unfinished.delete(0)
      unfinished_mjsnumbers = unfinished.keys.sort
      last_market_index = unfinished_mjsnumbers.find_index(last_market.to_i)
      next_market_id = unfinished_mjsnumbers[last_market_index + 1] unless last_market_index.nil?
      @market = if next_market_id.nil?
                  Market.find_by(mjsnumber: unfinished_mjsnumbers[0].to_s)
                else
                  Market.find_by(mjsnumber: next_market_id.to_s)
                end
    end
    respond_to do |format|
      format.turbo_stream { render 'profits/edit/fetch_market' }
    end
  end

  def update_completion
    old_completed_mjsnumbers = @profit.totals&.dig(:completion)&.keys
    old_completed_mjsnumbers ||= []
    @profit.set_completion
    @profit.save
    new_completed_mjsnumbers = @profit.totals&.dig(:completion)&.keys
    new_completed_mjsnumbers ||= []
    @fresh_completed = new_completed_mjsnumbers - old_completed_mjsnumbers
    respond_to do |format|
      format.turbo_stream { render 'profits/edit/update_completion' }
    end
  end

  def fetch_market
    @market = Market.find(params[:market_id])
    @profit = Profit.find(params[:profit])
    @profit ||= Profit.new
    respond_to do |format|
      format.turbo_stream { render 'profits/edit/fetch_market' }
    end
  end

  def fetch_volumes
    @profit = Profit.find(params[:id])
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace('profit_volume_container',
                   partial: 'profits/shared/volumes',
                   locals: { profit: @profit })
      end
    end
  end

  def edit_market
    @profit = Profit.find(params[:profit_id])
    @market = Market.find(params[:market_id])

    render partial: 'profits/edit/edit_market_profit_form', locals: { market: @market, profit: @profit }
  end

  # GET /profits/1/edit
  def edit
    unfinished = @profit.check_completion
    if unfinished.nil? || unfinished[0] == 0
      first_market
    else
      unfinished.delete(0)
      unfinished_mjsnumbers = unfinished.keys.sort
      @market = Market.find_by(mjsnumber: unfinished_mjsnumbers[0].to_s)
    end
    @product = Product.new
  end

  def new_by_date
    @profit = Profit.new(sales_date: params[:sales_date])
    @profit.date = from_nengapi(params[:sales_date])
    @profit.setup
    respond_to do |format|
      if @profit.save
        format.html { redirect_to edit_profit_path(@profit) }
      else
        format.html { redirect_to profits_url, notice: @profit.errors }
        format.json { render json: @profit.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /profits
  # POST /profits.json
  def create
    @profit = Profit.new(profit_params)
    @profit.date = from_nengapi(@profit.sales_date)
    @profit.setup
    respond_to do |format|
      if @profit.save
        format.html { redirect_to edit_profit_path(@profit) }
      else
        format.html { render :new_tabs, notice: @profit.errors }
        format.json { render json: @profit.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /profits
  # POST /profits.json
  def update
    @profit.process_update

    respond_to do |format|
      if @profit.save
        format.html { redirect_to profit_path(@profit) }
        format.json { render :show, status: :created, location: profit_url(@profit) }
      else
        format.html { render :edit }
        format.json { render json: @profit.errors, status: :unprocessable_entity }
      end
    end
  end

  def autosave
    @profit.new_figures = profit_params[:figures].to_h
    @profit.autosave

    if @profit.save
      render json: { status: 'success' }, status: :accepted
    else
      return logger.debug('empty autosave') if @profit.figures.empty?

      @profit.errors.full_messages.each do |error|
        logger.debug error.to_s
      end
    end
  end

  # DELETE /profits/1
  # DELETE /profits/1.json
  def destroy
    @profit.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@profit) }
      format.json { head :no_content }
      format.html { redirect_to profits_url }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_profit
    id = params[:id] || params[:profit_id]
    @profit = id ? Profit.find(id) : Profit.new
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def profit_params
    params.require(:profit).permit(:id, :sales_date, :debug_figures, { figures: {} })
  end

  def calendar_params
    params.permit(:start, :end, :_, :format)
  end
end
