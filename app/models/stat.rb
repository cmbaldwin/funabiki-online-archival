class Stat < ApplicationRecord
  include StatMutator

  has_many :profits, dependent: :nullify
  has_one :oyster_supply, dependent: :nullify
  has_many :rakuten_orders, dependent: :nullify
  has_many :yahoo_orders, dependent: :nullify
  has_many :funabiki_orders, dependent: :nullify
  has_many :infomart_orders, dependent: :nullify
  has_many :online_orders, dependent: :nullify
  has_many :furusato_orders, dependent: :nullify

  serialize :data
  serialize :weather

  validates :date, presence: true, uniqueness: true

  attr_accessor :stored_profits, :stored_supplies, :mukimi_count

  # Stats are generated automatically daily, the last Stat should always be today's Stat.
  # A season runs from October 1st to September 31st, splits occur in this way.

  # Today's Stat (also current season end stat)
  scope :get_most_recent, -> { order(date: :desc).first }
  # Curent season start Stat
  scope :get_season_start, -> { find_by(date: Stat.get_most_recent.season_start) }
  # Prior season's start Stat
  scope :get_prior_season_start, -> { find_by(date: Stat.get_most_recent.prior_season_start) }
  scope :get_prior_season_end, -> { where(date: prior_season_range).order(:date).first }
  scope :get_last_season_prior_to_last, -> { where(date: Stat.get_most_recent.prior_season_range).order(:date).last }

  def self.prior_season_range
    stat = Stat.get_most_recent
    stat.prior_season_start..stat.prior_season_end
  end

  def business_hours?
    hour = Time.zone.now.hour
    hour > 8 && hour < 20
  end

  def season_start
    date.month < 10 ? Date.new((date.year - 1), 10, 1) : Date.new(date.year, 10, 1)
  end

  def season_end
    date.month < 10 ? Date.new(date.year, 10, 1) : Date.new((date.year + 1), 10, 1)
  end

  def prior_season_start
    date.month < 10 ? Date.new((date.year - 2), 10, 1) : Date.new((date.year - 1), 10, 1)
  end

  def prior_season_end
    date.month < 10 ? Date.new((date.year - 1), 10, 1) : Date.new(date.year, 10, 1)
  end

  def this_season_range
    season_start..date
  end

  def prior_season_range
    prior_season_start..prior_season_end
  end

  def two_season_range
    prior_season_start..date
  end

  def set_references
    assign_references
    save
  end

  def set
    return unless date # If date is nil, Stat is being created, so don't set

    save unless persisted? # Get an ID to associate first
    assign_references # Set associations
    set_data
    save # Save the work
    @data = nil # Clear the data
  end

  def get_ref_model_by_str(str)
    str.singularize.classify.constantize
  end

  def update_references(references)
    references.find_each { |ref| ref.update(stat_id: id) }
  end

  def assign_ref_by_date(ref_model_str)
    ref_model = get_ref_model_by_str(ref_model_str)
    update_references(ref_model.where(date:))
  end

  def assign_ref_by_ship_date(ref_model_str)
    ref_model = get_ref_model_by_str(ref_model_str)
    update_references(ref_model.where(ship_date: date))
  end

  def assign_wholesale_refs
    %w[profit oyster_supply].each { |ref| assign_ref_by_date(ref) }
  end

  def assign_shop_refs
    FurusatoOrder.with_date(date).find_each { |order| order.update(stat_id: id) }
    RakutenOrder.with_date(date).find_each { |order| order.update(stat_id: id) }
    %w[yahoo_order infomart_order online_order funabiki_order].each { |ref| assign_ref_by_ship_date(ref) }
  end

  def assign_references
    logger.debug "Setting references for #{date}"
    assign_wholesale_refs
    assign_shop_refs
  end

  def print_average(chart_data, init_str)
    values = chart_data.values
    avg_str = values.empty? ? '0' : yenify(values.sum / values.length)
    "#{init_str}#{avg_str}"
  end

  def save_chart_data_averages(symbol_base, now, prior, prefix)
    @data[:"this_#{symbol_base}"] = print_average(now, prefix)
    @data[:"prior_#{symbol_base}"] = print_average(prior, prefix)
    two_year = now.merge(prior)
    @data[:"two_#{symbol_base}"] = print_average(two_year, prefix)
  end

  def accumulate_chart_data(symbol_base, prefix)
    logger.debug "Setting #{symbol_base} chart data"
    now = send("#{symbol_base}_chart_data", this_season_range)
    prior = send("#{symbol_base}_chart_data", prior_season_range)
    @data[:"#{symbol_base}_chart_data"] = now
    @data[:"prior_season_#{symbol_base}_chart_data"] = prior
    @data[:"#{symbol_base}_maximum"] = calculate_maximum(now, prior)
    save_chart_data_averages("season_#{symbol_base}_average", now, prior, prefix)
  end

  def accumulate_online_shop_data
    ## All online shop sales @data
    logger.debug 'Setting online shop sales data'
    @data[:all_online_shop_sales_data] = all_online_shop_sales_data
    @data[:prior_season_all_online_shop_sales_data] = all_online_shop_sales_data(this_season: false)
    @data[:all_online_order_count_data] = all_online_order_count_data
    @data[:prior_season_all_online_order_count_data] = all_online_order_count_data(this_season: false)
  end

  def accumulate_mukimi_online_sales_data
    ## Mukimi Online Sales
    logger.debug 'Setting online sales data for shucked oysters'
    @data[:online_order_mukimi_count] = set_mukimi_count
    @data[:online_order_mukimi_usage] = set_mukimi_count * 0.5
    @data[:online_order_all_mukimi_sales] = all_online_order_method_sum(:mukimi_sales_estimate)
    @data[:online_order_all_mukimi_profit] = all_online_order_method_sum(:mukimi_profit_estimate)
    @data[:online_order_mukimi_per_pack_profit] = online_order_mukimi_per_pack_profit
  end

  def accumulate_furusato_data
    # Accummulate furusato order data into weeks, sum the number of orders as the value
    @data[:furusato_count_data] = furusato_order_count_data
    @data[:prior_season_furusato_count_data] = furusato_order_count_data(this_season: false)
  end

  def set_data
    @data ||= {}

    accumulate_chart_data('market_profit', '￥')
    accumulate_chart_data('overhead', '￥')
    accumulate_chart_data('kilo_sales_estimate', '￥')
    accumulate_chart_data('farmer_kilo_costs', '￥')
    accumulate_chart_data('oyster_supply_volumes', 'kg')
    accumulate_chart_data('oyster_costs', '￥')
    accumulate_chart_data('total_profit_estimate', '￥')
    accumulate_online_shop_data
    accumulate_mukimi_online_sales_data
    accumulate_furusato_data

    self.data = @data
  end

  def forcast_keys
    %i[shell_count triploid_count mukimi_count bara_count]
  end

  def actual_order_counts
    actual = {}
    all_orders(*forcast_keys).flatten(1).transpose.map(&:sum).each_with_index { |sum, i| actual[forcast_keys[i]] = sum }
    actual
  end

  def self_count
    count = data[:actual_order_counts]
    return count if count

    data[:actual_order_counts] = actual_order_counts
    save
    data[:actual_order_counts]
  end

  def shop_models
    [RakutenOrder, YahooOrder, InfomartOrder, OnlineOrder, FunabikiOrder]
  end

  def shop_models_plural_strings
    shop_models.map { |model| model.model_name.to_s.underscore.pluralize }
  end

  def human_model_name(model)
    model.model_name.human
  end

  def model_count_from_str(model)
    public_send(model.model_name.to_s.underscore.pluralize).count
  end

  def print_seperated_orders
    shop_models.map { |model| ["#{human_model_name(model)}: #{model_count_from_str(model)}"] }
  end

  def orders_count
    shop_models_plural_strings.map { |references| public_send(references).length }.sum
  end

  def all_orders(*methods_array)
    shop_models_plural_strings.map do |references|
      public_send(references).map do |order|
        methods_array.map { |method_sym| order.public_send(method_sym) }
      end
    end
  end

  def accumulate_profit_total(date, sales, profit)
    sales[date] ||= nil
    return unless profit.totals[:profits]

    sales[date] ||= 0
    sales[date] += (profit.totals[:profits] / 10_000) if profit.totals[:profits].positive?
  end

  def get_stored_profits(range)
    stored_profits ||= Profit.with_date(two_season_range)
    stored_profits.with_date(range)
  end

  def accumulate_market_data(range)
    sales = {}
    get_stored_profits(range).each do |profit|
      next unless profit

      date = profit.date
      accumulate_profit_total(date, sales, profit)
    end
    sales.compact.sort_by { |date, _sales| date }
  end

  def market_profit_chart_data(range)
    accumulate_market_data(range).to_h
  end

  def accumulate_overhead_data(range)
    overhead = {}
    get_stored_profits(range).each do |profit|
      next unless profit&.totals&.[](:expenses)

      date = profit.date
      overhead[date] = profit.totals[:expenses] + profit.totals[:extras]
    end
    overhead.compact.sort_by { |date, _overhead| date }
  end

  def overhead_chart_data(range)
    accumulate_overhead_data(range).to_h
  end

  def calculate_maximum(chart_data_hash_one, chart_data_hash_two)
    return 0 unless chart_data_hash_one.nil? || chart_data_hash_two.nil?

    figures = chart_data_hash_one.merge(chart_data_hash_two).values.max
    return 0 unless figures

    figures.round(-(figures.to_i.to_s.length - 4))
  end

  def accumulate_sales_estimates(range)
    sales = {}
    get_stored_profits(range).each do |profit|
      next unless profit

      date = profit.date
      accumulate_sales_estimate(date, profit, sales)
    end
    sales.compact.sort_by { |date, _sales| date }
  end

  def accumulate_sales_estimate(date, profit, sales)
    volumes = profit.volumes
    return unless volumes && profit&.totals&.dig(:profits)

    kilo_price = (profit.totals[:profits] / (volumes[:total_volume] / 1000)).round(0) # yen per kilo
    kilo_price = 0 unless kilo_price.positive?
    sales[date] ||= kilo_price
    # Go with lowest of the set
    sales[date] = kilo_price if kilo_price.to_i < sales[date].to_i
  end

  def kilo_sales_estimate_chart_data(range)
    accumulate_sales_estimates(range).to_h
  end

  def get_stored_supplies(range)
    stored_supplies ||= OysterSupply.with_date(two_season_range)
    stored_supplies.with_date(range)
  end

  def accumulate_oyster_supply_costs(range)
    costs = {}
    get_stored_supplies(range).each do |supply|
      next unless supply

      date = supply.date
      accumulate_kilo_cost(costs, date, supply)
    end
    costs.compact.sort_by { |date, _cost| date }
  end

  def accumulate_kilo_cost(costs, date, supply)
    kilo_price = supply.totals[:cost_total]
    volume = supply.totals[:mukimi_total]
    kilo_price = kilo_price.zero? || volume.zero? ? nil : (kilo_price / volume).round(0)
    costs[date] = kilo_price
    costs[date] = nil if costs[date].nil?
  end

  def farmer_kilo_costs_chart_data(range)
    accumulate_oyster_supply_costs(range).to_h
  end

  def accumulate_oyster_volume_date(date, volume, supply)
    supply_volume = supply.totals[:mukimi_total]
    volume[date] = supply_volume.zero? ? nil : supply_volume
  end

  def accumulate_oyster_volumes(range)
    volume = {}
    get_stored_supplies(range).each do |supply|
      next unless supply

      date = supply.date
      accumulate_oyster_volume_date(date, volume, supply)
    end
    volume.compact.sort_by { |date, _volume| date }
  end

  def oyster_supply_volumes_chart_data(range)
    accumulate_oyster_volumes(range).to_h
  end

  def accumulate_oyster_cost(costs, date, supply)
    total_cost = supply.totals[:cost_total]
    costs[date] = total_cost.zero? ? nil : total_cost
  end

  def oyster_costs_chart_data(range)
    costs = {}
    get_stored_supplies(range).each do |supply|
      next unless supply

      date = supply.date
      accumulate_oyster_cost(costs, date, supply)
    end
    costs.compact.sort_by { |date, _cost| date }.to_h
  end

  def estimate_shell_profits(range)
    shell_profits = {}
    get_stored_supplies(range).each do |supply|
      next unless supply

      # Conservative profit estimate per shell, hard coded for now
      profit_per_shell = 40
      date = supply.date
      shell_profits[date] = supply.totals[:shell_total] * profit_per_shell
    end
    shell_profits
  end

  def accumulate_profit_totals(position, date)
    position << (@totals_estimate_market_profit[date] * 10_000) if @totals_estimate_market_profit[date]
    position << -@totals_estimate_oyster_costs[date] if @totals_estimate_oyster_costs[date]
    position << @totals_estimate_shell_profits[date] if @totals_estimate_shell_profits[date]
    # Hard coding a loss of 18 percent and a conservative 2300 yen per kilo profit for frozen mukimi
    position << (@totals_estimate_frozen_weight[date] * 0.82 * 2300) if @totals_estimate_frozen_weight[date]
  end

  def collect_online_mukimi_profit(position, date)
    stat = Stat.find_by(date:)
    return unless stat&.data

    position << stat.data.fetch(:online_order_all_mukimi_profit, 0)
  end

  def fill_total_profit_dates_and_sum(profit, dates)
    # if there are an odd number of dates, add a date key to the end with an empty array
    if dates.length.odd?
      key = month_and_week_number(dates.last + 1.week)
      profit[key] = [0]
    end
    # sum the values for each week
    profit.transform_values!(&:sum)
  end

  def frozen_weight_chart_data(range)
    frozen_weight = {}
    get_stored_supplies(range).each do |supply|
      next unless supply

      date = supply.date
      weight = supply.frozen_mukimi_weight || 0
      frozen_weight[date] = supply.frozen_mukimi_weight || 0
    end
    frozen_weight
  end

  def total_profit_estimate_chart_data(range)
    @totals_estimate_oyster_costs = oyster_costs_chart_data(range).to_h
    @totals_estimate_market_profit = market_profit_chart_data(range).to_h
    @totals_estimate_shell_profits = estimate_shell_profits(range).to_h
    @totals_estimate_frozen_weight = frozen_weight_chart_data(range).to_h
    fetch_keys = ->(array_of_hashes) { array_of_hashes.map(&:keys).flatten.uniq }
    dates = fetch_keys.call([@totals_estimate_oyster_costs, @totals_estimate_market_profit,
                             @totals_estimate_shell_profits, @totals_estimate_frozen_weight])
    profit = {}
    dates.sort.each do |date|
      # create key that is month and week number
      key = month_and_week_number(date)
      # collect values in array for each day associated with the week, add news ones to the end
      profit[key] ||= []
      accumulate_profit_totals(profit[key], date)
      collect_online_mukimi_profit(profit[key], date)
    end
    fill_total_profit_dates_and_sum(profit, dates)
    # combine every two keys and values into one combination key value pair
    # profit = profit.to_a.each_slice(2).to_h { |(k1, v1), (k2, v2)| [[k1, k2].join(' ~ '), v1.to_f + v2.to_f] }
    profit
  end

  def all_online_shop_sales_data(this_season: true)
    accumulator = get_online_orders(this_season).map do |records|
      [records.model_name.plural.to_sym, get_sales(records)] if records
    end
    accumulator.compact.to_h
  end

  def get_online_orders(this_season)
    range = this_season ? this_season_range : prior_season_range
    shop_models.map { |shop| shop.with_dates(range) }
  end

  def get_sales(shop_orders)
    Rails.logger.debug "Getting sales for #{shop_orders.model_name}"
    shop_orders.group_by_week(series: true, &:order_time).transform_values { |v| v.map(&:total_price).compact.sum.to_i }
  end

  def get_counts(shop_orders)
    shop_orders.group_by_week(series: true, &:order_time).transform_values(&:length)
  end

  def all_online_order_count_data(this_season: true)
    accumulator = get_online_orders(this_season).map do |records|
      [records.model_name.plural.to_sym, get_counts(records)] if records
    end
    accumulator.compact.to_h
  end

  def all_online_order_method_sum(method_sym)
    all_orders(method_sym).flatten.sum
  end

  def set_mukimi_count
    mukimi_count ||= all_online_order_method_sum(:mukimi_count)
    mukimi_count
  end

  def online_order_mukimi_per_pack_profit
    return 0 unless set_mukimi_count.positive?

    arr = all_orders(:pack_profit_estimate).flatten.reject(&:zero?)
    arr.sum / arr.length
  end

  def furusato_order_count_data(this_season: true)
    FurusatoOrder.with_dates(this_season ? this_season_range : prior_season_range).group_by_week(series: true,
&:order_time).transform_values(&:length).compact.to_h
  end
end
