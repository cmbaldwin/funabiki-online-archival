class MarketsController < ApplicationController
  before_action :set_market, only: %i[show edit update destroy new index_market update_index_market]
  before_action :check_status

  def check_status
    return unless !current_user.approved? || current_user.supplier? || current_user.user?
    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  # GET /markets
  # GET /markets.json
  def index; end

  def index_markets
    @markets = Market.order('mjsnumber').active
    render partial: 'markets/index/markets', locals: { markets: @markets }
  end

  def index_market
    render partial: 'markets/index/market', locals: { market: @market }
  end

  def update_index_market
    @market.update(market_params)
    render turbo_stream: turbo_stream.replace("market_#{@market.id}", partial: 'markets/index/market', locals: { market: @market })
  end

  # GET /markets/1
  # GET /markets/1.json
  def show
    render turbo_stream: turbo_stream.replace('market_form', partial: 'market', locals: { market: @market })
  end

  # GET /markets/new
  def new
    render turbo_stream: turbo_stream.replace('market_form', partial: 'market', locals: { market: @market })
  end

  # GET /markets/1/edit
  def edit
    render turbo_stream: turbo_stream.replace("market_#{@market.id}", partial: 'markets/index/edit_market', locals: { market: @market })
  end

  # POST /markets
  # POST /markets.json
  def create
    @market = Market.new(market_params)

    respond_to do |format|
      if @market.save
        format.html { redirect_to @market, notice: '市場を作成されました。' }
        format.json { render :show, status: :created, location: @market }
      else
        format.html { render :new }
        format.json { render json: @market.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /markets/1
  # PATCH/PUT /markets/1.json
  def update
    respond_to do |format|
      if @market.update(market_params)
        format.html { redirect_to @market, notice: '市場を編集されました。' }
        format.json { render :show, status: :ok, location: @market }
      else
        format.html { render :edit }
        format.json { render json: @market.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /markets/1
  # DELETE /markets/1.json
  def destroy
    @market.active = false

    respond_to do |format|
      format.html { redirect_to markets_url, notice: '市場を休止されました。' }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@market) }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_market
      id = params[:id] || params[:market_id]
      @market = id ? Market.find(id) : Market.new
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def market_params
      params.require(:market).permit(:mjsnumber, :namae, :color, :nick, :zip, :address, :brokerage, :phone, :repphone, :fax, :cost, :block_cost, :one_time_cost, :one_time_cost_description, :optional_cost, :optional_cost_description, :handling, :active, product_ids: [])
    end
end
