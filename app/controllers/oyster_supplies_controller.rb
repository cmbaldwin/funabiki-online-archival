class OysterSuppliesController < ApplicationController
  before_action :set_oyster_supply, only: %i[show edit tippy_stats update destroy supply_check]
  before_action :check_status
  before_action :set_info, only: %i[show edit new_by update destroy supply_check supply_price_actions]
  before_action :set_action_params,
                only: %i[supply_previews_actions supply_invoice_actions supply_price_actions
                         supply_stats tippy_stats]
  before_action :setup_set_price_range, only: %i[set_prices supply_stats]

  def check_status
    return unless !current_user.approved? || current_user.supplier? || current_user.user? || current_user.employee?

    flash.now[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  def set_info
    @sakoshi_suppliers = Supplier.where(location: '坂越').order(:supplier_number)
    @aioi_suppliers = Supplier.where(location: '相生').order(:supplier_number)
    @all_suppliers = @sakoshi_suppliers + @aioi_suppliers
    @receiving_times = %w[am pm]
    @types = %w[large small eggy damaged large_shells small_shells thin_shells small_triploid_shells triploid_shells
                large_triploid_shells xl_triploid_shells]
    @supplier_numbers = @sakoshi_suppliers.pluck(:id).map(&:to_s)
    @supplier_numbers += @aioi_suppliers.pluck(:id).map(&:to_s)
  end

  def location_to_locale(location)
    locale_hash = { 'sakoshi' => '坂越', 'aioi' => '相生', 'oku' => '邑久', 'iri' => '伊里', 'hinase' => '日生' }
    locale_hash[location]
  end

  def oyster_supply_set
    return if @oyster_supply

    @oyster_supply = OysterSupply.find_by(date: Time.zone.today)
    @oyster_supply ||= OysterSupply.new
    @oyster_supply.do_setup
  end

  # GET /oyster_supplies/fetch_invoice/:id
  def fetch_invoice
    @oyster_invoice = OysterInvoice.find(params[:id])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace('supply_action_partial',
                   partial: 'oyster_supplies/invoice/invoice',
                   locals: { oyster_invoice: @oyster_invoice })
      end
    end
  end

  def set_action_params
    @start_date = action_params[:start_date]
    @end_date = action_params[:end_date]
  end

  def setup_set_price_range
    @start_date = set_price_params[:start_date]
    @end_date = set_price_params[:end_date]
  end

  def supply_previews_actions
    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def supply_invoice_actions
    invoice_setup(@start_date, @end_date)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace('supply_action_partial',
                   partial: 'oyster_supplies/supply_modal/supply_invoice_actions',
                   locals: { oyster_invoice: @oyster_invoice })
      end
    end
  end

  def invoice_setup(start_date, end_date)
    @oyster_invoice = OysterInvoice.new(
      start_date:,
      end_date:,
      aioi_emails: ENV.fetch('AIOI_EMAILS', nil),
      sakoshi_emails: ENV.fetch('SAKOSHI_EMAILS', nil),
      data: {
        passwords: invoice_passwords
      },
      completed: false
    )
  end

  def supply_price_actions
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace('supply_action_partial', partial: 'oyster_supplies/supply_modal/supply_price_actions')
      end
    end
  end

  # POST set_prices/:start_date/:end_date
  def set_prices
    dates = (DateTime.parse(@start_date)..(DateTime.parse(@end_date) - 1.day))
    @altered = {}
    OysterSupply.with_date(dates).each do |supply|
      supply.update_and_fix_calculations
      supply.update_prices(set_price_params['[prices]'], @altered)
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace('supply_action_partial', partial: 'oyster_supplies/pricing/set_price_results', locals: { altered: @altered })
      end
    end
  end

  def supply_stats
    dates = (Date.parse(@start_date)..(Date.parse(@end_date) - 1.day))
    @supplies = OysterSupply.with_date(dates)
    @profits = Profit.with_date(dates)
    @rakuten_orders = RakutenOrder.with_dates(dates:)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream
          .replace('supply_action_partial', partial: 'oyster_supplies/supply_stats/supply_stats',
                                            locals: { supplies: @supplies, profits: @profits,
                                                      rakuten_orders: @rakuten_orders })
      end
    end
  end

  def tippy_stats
    @stat = params[:stat]
    supply_date = DateTime.strptime(@oyster_supply.supply_date, '%Y年%m月%d日')
    last_year_three_day_period = [to_nengapi(supply_date - 1.year), to_nengapi(supply_date - 1.year - 1.day),
                                  to_nengapi(supply_date - 1.year - 2.days)]

    @previous_supply = @oyster_supply.previous
    @two_previous_supply = @previous_supply.previous if @previous_supply
    @ly_supply = OysterSupply.where(supply_date: last_year_three_day_period).first
    @ly_next_supply = @ly_supply.next if @ly_supply
    @ly_prev_supply = @ly_supply.previous if @ly_supply

    respond_to do |format|
      format.html { render 'oyster_supplies/supply_stats/tippy_stats', layout: false }
    end
  end

  def invoice_passwords
    {
      'sakoshi_all_password' => SecureRandom.hex(4).to_s,
      'sakoshi_seperated_password' => SecureRandom.hex(4).to_s,
      'aioi_all_password' => SecureRandom.hex(4).to_s,
      'aioi_seperated_password' => SecureRandom.hex(4).to_s
    }
  end

  def fetch_supply_range(start_date, end_date)
    offset = 14.days
    start_date = Date.strptime(start_date) if start_date
    start_date ||= Time.zone.today.at_beginning_of_month - offset
    end_date = Date.strptime(end_date) if end_date
    end_date ||= Time.zone.today.end_of_month + offset
    start_date..end_date
  end

  # GET /fetch_supplies
  # GET /fetch_supplies.js
  def fetch_supplies
    range = fetch_supply_range(calendar_params['start'], calendar_params['end'])
    @oyster_supply = OysterSupply.where(date: range)
    @oyster_invoices = OysterInvoice.where(start_date: range)
    @holidays = japanese_holiday_background_events(range)
  end

  # GET /oyster_supplies
  # GET /oyster_supplies.json
  def index
    fetch_supplies
    @invoice = OysterInvoice.new
    @place = calendar_params[:place]
  end

  def supply_check
    @filename = "原料チェック表（#{@oyster_supply.supply_date}）.pdf"
    print_receiving_times = params[:receiving_times].map { |time| @oyster_supply.kanji_am_pm(time) }.join('/')
    message = Message.new(
      user: current_user.id,
      model: 'oyster_supply',
      state: false,
      message: "#{@oyster_supply.supply_date} #{print_receiving_times} 牡蠣原料受入れチェック表を作成中…",
      data: {
        oyster_supply_id: @oyster_supply.id,
        filename: @filename,
        expiration: (DateTime.now + 1.day)
      }
    )
    message.save
    OysterSupplyCheckWorker.perform_async(@oyster_supply.id, message.id, params[:receiving_times])
    head :ok
  end

  # GET /oyster_supplies/payment_pdf/:format/:layout/:start_date/:end_date/:location
  def invoice_preview
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    location = params[:location]
    invoice_format = params[:invoice_format]
    layout = params[:layout]
    message = Message.new(
      user: current_user.id,
      model: 'oyster_invoice',
      state: false,
      message: '牡蠣原料仕切りプレビュー作成中…',
      data: {
        invoice_id: 0,
        expiration: (DateTime.now + 1.day),
        invoice_preview: {
          start_date:,
          end_date:,
          location:,
          format: invoice_format,
          layout:
        }
      }
    )
    message.save
    InvoicePreviewWorker.perform_async(start_date, end_date, location, invoice_format, layout, message.id)
    head :ok
  end

  # GET /oyster_supplies/1
  # GET /oyster_supplies/1.json
  def show; end

  # GET /oyster_supplies/1/edit
  def edit; end

  def new
    oyster_supply_set
  end

  # GET /oyster_supplies/new
  def new_by
    date = Date.parse(new_by_params[:supply_date])
    @oyster_supply = OysterSupply.find_or_initialize_by(date:)
    if @oyster_supply.new_record?
      @oyster_supply.do_setup
      @oyster_supply.save
    end

    respond_to do |format|
      format.html { redirect_to @oyster_supply }
    end
  end

  # POST /oyster_supplies
  # POST /oyster_supplies.json
  def create
    @oyster_supply = OysterSupply.new(oyster_supply_params)
    respond_to do |format|
      if @oyster_supply.save
        format.html { redirect_to @oyster_supply }
        format.json { render :show, status: :created, location: @oyster_supply }
      else
        format.html { render :new, notice: @oyster_supply.errors }
        format.json { render json: @oyster_supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /oyster_supplies/1
  # PATCH/PUT /oyster_supplies/1.json
  def update
    if @oyster_supply.update(oyster_supply_params)
      @oyster_supply.update_and_fix_calculations
      head :no_content
      # format.html { redirect_to @oyster_supply }
      # format.json { render :show, status: :ok, location: @oyster_supply }
    else
      render json: @oyster_supply.errors, status: :unprocessable_entity
      # format.html { render :edit }
      # format.json { render json: @oyster_supply.errors, status: :unprocessable_entity }
    end
  end

  # DELETE /oyster_supplies/1
  # DELETE /oyster_supplies/1.json
  def destroy
    @oyster_supply.destroy
    respond_to do |format|
      format.html { redirect_to oyster_supplies_url, notice: '牡蠣原料を削除しました' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_oyster_supply
    @oyster_supply = OysterSupply.find(params[:id])
    # In case we're viewing a pre-okayama supply
    @oyster_supply.okayama_setup if @oyster_supply.oysters['okayama'].nil?
  end

  def oyster_supply_action_params
    params.permit(:start_date, :end_date, :oyster_supply)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def oyster_supply_params
    params.require(:oyster_supply).permit(:supply_date, :oyster_invoice, :oyster_invoice_id, :frozen_mukimi_weight, oysters: {})
  end

  def new_by_params
    params.permit(:supply_date)
  end

  def action_params
    params.permit!
  end

  def calendar_params
    params.permit(:place, :start, :end, :_, :format)
  end

  def set_price_params
    params.permit(:authenticity_token, :start_date, :end_date, :commit, :oyster_supply, '[prices]': {})
  end
end
