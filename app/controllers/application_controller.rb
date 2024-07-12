class ApplicationController < ActionController::Base
  include CsvProcessing
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :check_user
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :set_access_control_headers

  before_action :set_locale
  def check_user
    return if current_user&.approved? || !current_user&.user? || !current_user&.employee?

    authentication_notice
  end

  def check_admin
    return if current_user.admin?

    authentication_notice
  end

  def authentication_notice
    flash[:notice] = 'そのページはアクセスできません。'
    redirect_to root_path, error: 'そのページはアクセスできません。'
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
    Carmen.i18n_backend.locale = params[:locale]&.to_sym || I18n.default_locale
  end

  def set_access_control_headers
    # only in test env
    return unless Rails.env.test?

    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def csv_processing; end

  def process_csv
    option = params[:processing_option]
    document = params[:document]

    process_csv_file(document, option)
    redirect_back(fallback_location: root_path)
  end

  def japanese_holiday_background_events(range)
    Rails.cache.fetch("japanese_holiday_background_events_#{range}") do
      japanese_holidays = HolidayJp.between(range.first - 7.days, range.last + 7.days) # from Gem
      ichiba_holidays = BrowseBot.new.ichiba_holiday_events(range)
      events = japanese_holidays.each_with_object([]) do |holiday, memo|
        memo << { title: holiday.name, className: 'bg-secondary bg-opacity-20',
                  start: holiday.date, end: holiday.date, display: 'background' }
      end
      events.concat(range.each_with_object([]) do |date, memo|
                      (if ichiba_holidays.include?(date)
                         (memo << { className: 'bg-secondary bg-opacity-30', start: date, end: date,
                                    display: 'background' })
                       end)
                    end)
    end
  end

  def time_setup
    @today = Time.zone.today
    @this_season_start = Rails.cache.fetch("this_season_start_#{@today}") do
      Time.zone.today.month < 10 ? Date.new((Time.zone.today.year - 1), 10, 1) : Date.new(Time.zone.today.year, 10, 1)
    end
    @this_season_end = Rails.cache.fetch("this_season_end_#{@today}") do
      Time.zone.today.month < 10 ? Date.new(Time.zone.today.year, 10, 1) : Date.new((Time.zone.today.year + 1), 10, 1)
    end
    @prior_season_start = Rails.cache.fetch("prior_season_start_#{@today}") do
      if Time.zone.today.month < 10
        Date.new((Time.zone.today.year - 2), 10,
                 1)
      else
        Date.new((Time.zone.today.year - 1), 10, 1)
      end
    end
    @prior_season_end = Rails.cache.fetch("prior_season_end_#{@today}") do
      Time.zone.today.month < 10 ? Date.new((Time.zone.today.year - 1), 10, 1) : Date.new(Time.zone.today.year, 10, 1)
    end
  end

  def from_nengapi(date)
    Date.strptime(date, '%Y年%m月%d日')
  end

  def to_nengapi(datetime)
    datetime.strftime('%Y年%m月%d日')
  end

  def nengapi_maker(date, plus)
    (date + plus).strftime('%Y年%m月%d日')
  end

  def rakuten_check
    @rakuten_shinki = Rakuten::Api.new.unprocessed_order_details
  end

  def shop_symbol_to_human(sym)
    sym.to_s.singularize.classify.constantize.model_name.human
  end

  protected

  def configure_permitted_parameters
    added_attrs = %i[username email password password_confirmation remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
