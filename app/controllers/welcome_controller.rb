class WelcomeController < ApplicationController
  include RakutenOrdersHelper
  include FurusatoOrdersHelper
  include YahooOrdersHelper

  before_action :time_setup, only: %i[yahoo_orders_partial new_yahoo_orders_modal daily_expiration_cards]
  before_action :yahoo_setup, only: %i[yahoo_orders_partial new_yahoo_orders_modal]
  before_action :rakuten_check, only: %i[rakuten_shinki_modal rakuten_orders_fp]

  # INDEX
  def index
    respond_to(&:html)
  end

  # MODALS
  def new_yahoo_orders_modal
    render partial: 'welcome/modals/new_yahoo_orders_modal'
  end

  def rakuten_shinki_modal
    render partial: 'welcome/modals/rakuten_shinki_modal'
  end

  def funabiki_orders_modal
    @new_orders = FunabikiOrder.unprocessed

    render partial: 'welcome/modals/funabiki_orders_modal'
  end

  def infomart_shinki_modal
    @infomart_shinki = InfomartOrder.where(ship_date: nil, status: '発注済')

    render partial: 'welcome/modals/infomart_shinki_modal'
  end

  # WIDGETS
  def rakuten_orders_fp
    @search_date = Time.zone.today
    @daily_orders = RakutenOrder.with_date(@search_date).order(:order_time)
    @daily_orders += RakutenOrder.where(ship_date: []).order(:order_time) if @search_date == Time.zone.today

    render partial: 'welcome/widgets/rakuten_orders'
  end

  def yahoo_orders_partial
    render partial: 'welcome/widgets/yahoo_orders'
  end

  def funabiki_orders_partial
    @search_date = Time.zone.today
    @daily_orders = FunabikiOrder.with_date(@search_date)
    @new_orders = FunabikiOrder.unprocessed

    render partial: 'welcome/widgets/funabiki_orders'
  end

  def front_infomart_orders
    @date = Time.zone.today
    @infomart_orders = InfomartOrder.where(ship_date: @date)

    @infomart_shinki = InfomartOrder.where(ship_date: nil, status: '発注済')

    render partial: 'welcome/widgets/infomart_orders'
  end

  def receipt_partial
    render partial: 'welcome/widgets/receipt'
  end

  def printables
    render partial: 'welcome/widgets/printables'
  end

  def charts_partial
    render partial: 'welcome/widgets/charts'
  end

  def daily_expiration_cards
    expiration_card_links_setup

    render partial: 'welcome/widgets/daily_expiration_cards'
  end

  # RECIEPTS
  def reciept
    # Set the options
    @options = reciept_options
    @filename = "#{@options[:purchaser]}の領収証(#{DateTime.now}).pdf"
    message = Message.new(user: current_user.id,
                          model: 'reciept',
                          state: false,
                          message: "#{@options[:purchaser]}の領収証を作成中…",
                          data: {
                            options: @options,
                            filename: @filename,
                            expiration: (DateTime.now + 1.day)
                          })
    message.save
    RecieptWorker.perform_async(@options, message.id)
    head :ok
  end

  private

  # SETUP
  def expiration_card_links_setup
    ExpirationCard.preload(:download)
    # Sakoshi cards search
    sakoshi_exp_card_setup
    # Aioi cards search
    aioi_exp_card_setup
  end

  def sakoshi_exp_card_setup
    @sakoshi_exp_today = ExpirationCard.sakoshi_exp_card(0, 4)
    @sakoshi_exp_today_five = ExpirationCard.sakoshi_exp_card(0, 5)
    @sakoshi_exp_tomorrow = ExpirationCard.sakoshi_exp_card(1, 5)
    @sakoshi_exp_tomorrow_five = ExpirationCard.sakoshi_exp_card(1, 6)
    @sakoshi_exp_today_five_expo = ExpirationCard.sakoshi_exp_card(0, 5, print_made_on: false)
    @sakoshi_exp_muji = ExpirationCard.muji
    @sakoshi_exp_frozen = ExpirationCard.sakoshi_frozen
    @sakoshi_sanbaitai = ExpirationCard.sakoshi_sanbaitai
  end

  def aioi_exp_card_setup
    @aioi_exp_today = ExpirationCard.aioi_exp_card(0, 4)
    @aioi_exp_today_five = ExpirationCard.aioi_exp_card(0, 5)
    @aioi_exp_tomorrow = ExpirationCard.aioi_exp_card(1, 5)
    @aioi_exp_tomorrow_five = ExpirationCard.aioi_exp_card(1, 6)
    @aioi_exp_today_five_expo = ExpirationCard.aioi_exp_card(0, 5, print_made_on: false)
    @aioi_exp_muji = ExpirationCard.muji(is_sakoshi: false)
    @aioi_exp_frozen = ExpirationCard.aioi_frozen
  end

  def yahoo_setup
    @yahoo_orders = YahooOrder.with_date(Time.zone.today)
    @yahoo_date = DateTime.now
    @new_yahoo_orders = YahooOrder.undated.order(:order_id)
  end

  def reciept_options
    params.require(:reciept_options)
          .permit(:sales_date, :order_id, :purchaser, :title, :amount, :expense_name, :oysis, :tax_8_amount, :tax_8_tax, :tax_10_amount, :tax_10_tax)
  end
end
