class Profit < ApplicationRecord
  include OysterEstimates
  before_save :set_ampm
  before_save :check_age
  before_destroy :check_age

  belongs_to :stat, optional: true
  has_many :profit_and_market_joins
  has_many :markets, through: :profit_and_market_joins
  has_many :profit_and_product_joins
  has_many :products, through: :profit_and_product_joins

  serialize :figures
  serialize :totals
  serialize :subtotals
  serialize :volumes

  attr_accessor :new_figures

  validates :figures,
            presence: true,
            length: { minimum: 1 }
  validates :sales_date,
            presence: true,
            length: { minimum: 1 }
  validates :date,
            presence: true

  scope :with_date, ->(date) { where(date: [date]) }

  include OrderQuery
  order_query :profit_query,
              [:sales_date] # Sort :sales_date in :desc order

  # Reference for accessing data from the figures hash
  # self.figures.each do |type_number, type_hash|
  #   type_hash.each do |product_id, product_hash|
  #     product_hash.each do |market_id, values_hash|
  #       values_hash[:order_count] => (floating-point)
  #       values_hash[:unit_price ] => (floating-point)
  #       values_hash[:combined] => (0=false/1=true)
  #       values_hash[:extra_cost] => (0=false/1=true)
  #     end
  #   end
  # end

  def setup
    self.figures = { 0 => 0 }
    self.totals = { completion: { 0 => 0 } }
    set_ampm
  end

  def set_ampm
    # am == true, pm == false
    self.ampm = check_ampm unless alone? # Don't set if there's only one
  end

  def check_age
    return true unless id # New record

    # Too old to edit (more than 3 months old)
    return unless (Time.zone.now - created_at) / 2_592_000 > 3

    errors.add(:base, 'この計算書は編集できません')
    throw(:abort)
  end

  def alone?
    Profit.where(date:).length == 1 # Only one profit for this date
  end

  def linked_profit
    Profit.where(date:, ampm: !ampm).first
  end

  def check_ampm
    # Tokyo will always be shipped in the AM, Tokyo is 1, hard-coded
    market_ids.include?(1)
  end

  def check_completion
    set_completion
    totals[:completion]
  end

  def set_completion
    totals[:completion] = calc_completion
  end

  def calc_completion
    unfinished = { 0 => 0 }
    add_unfinished_figures_to_completion(unfinished) if figures && figures[0].nil?
    unfinished
  end

  def incomplete?
    set_completion unless totals[:completion]
    totals[:completion][0].positive?
  end

  def figures_unfinished?(values_hash)
    ocou = values_hash[:order_count].to_f
    upri = values_hash[:unit_price].to_f
    (ocou.positive? && upri.positive?) || (!ocou.positive? && !upri.positive?)
  end

  def unprofitable_products
    Rails.cache.fetch("unprofitable_product_ids_#{Product.unprofitable.cache_key}", expires_in: 12.hours) do
      Product.unprofitable.pluck(:id)
    end
  end

  def add_unfinished_figures_to_completion(unfinished)
    # Fetch mjsnumbers for all markets at once
    mjsnumbers = Rails.cache.fetch('mjsnumbers', expires_in: 1.day) do
      Market.pluck(:id, :mjsnumber).to_h
    end

    figures.each do |_type_number, type_hash|
      type_hash.each do |product_id, product_hash|
        # Add to unfinished if it's a profitable product
        next if unprofitable_products.include?(product_id)

        product_hash.each do |market_id, values_hash|
          # Skip if both have values, or neither have values
          next if figures_unfinished?(values_hash)

          # Pass mjsnumbers hash to add_figure_to_unfinished
          add_figure_to_unfinished(market_id, unfinished, product_id, mjsnumbers)
        end
      end
    end
  end

  def add_figure_to_unfinished(market_id, unfinished, product_id, mjsnumbers)
    # Look up mjsnumber in mjsnumbers hash
    mjsnumber = mjsnumbers[market_id]

    unfinished[mjsnumber] = [] if unfinished[mjsnumber].nil?
    unfinished[mjsnumber] << product_id
    unfinished[0] += 1
  end

  def total_rankings
    stats_hash = {}
    subtotals.each do |k, v|
      next unless k.respond_to?('to_i') && v.is_a?(Hash)

      v.each do |product_number, values|
        next unless product_number.respond_to?('to_i')

        stats_hash[product_number] = values
      end
    end
    stats_hash.sort_by { |_k, v| v[:product_boxes_sold] }.reverse
  end

  def type_rankings
    stats_hash = {}
    subtotals.each do |k, v|
      next unless k.respond_to?('to_i')

      stats_hash[k] = {} unless stats_hash[k].is_a?(Hash)
      next unless v.is_a?(Hash)

      v.each do |product_number, values|
        stats_hash[k][product_number] = values if product_number.respond_to?('to_i')
      end
    end
    stats_hash
  end

  def mizukiri_subtotals
    if subtotals['3']
      subtotals['3'].each_with_object({}) { |(k, v), memo| memo[k] = v if k.respond_to?('to_i') }
    else
      {}
    end
  end

  def mizukiri_tanka(figs)
    figs[:gohyaku_tanka] = ((figs[:gohyaku_profits] / figs[:gohyaku_total]) * 2).to_i unless figs[:gohyaku_total].zero?
    figs[:kilo_tanka] = (figs[:kilo_profits] / figs[:kilo_total]).to_i unless figs[:kilo_total].zero?
    figs
  end

  def mizukiri_half_kilo(figs, values)
    figs[:gohyaku_total] += values[:products_sold]
    figs[:gohyaku_profits] += values[:product_sales] - values[:product_expenses]
  end

  def mizukiri_kilo(figs, values)
    figs[:kilo_total] += values[:products_sold]
    figs[:kilo_profits] += values[:product_sales] - values[:product_expenses]
  end

  def mizukiri_figures
    figs = { gohyaku_total: 0, kilo_total: 0, gohyaku_profits: 0, kilo_profits: 0, gohyaku_tanka: 0, kilo_tanka: 0 }
    mizukiri_subtotals.each do |_product_id, values|
      case values[:product_name]
      when /500g/ then mizukiri_half_kilo(figs, values)
      when /1キロ/ then mizukiri_kilo(figs, values)
      end
    end
    mizukiri_tanka(figs)
  end

  # Methods for autosave functionality
  def num_keys_to_integers(string_figures)
    string_figures.deep_transform_keys! { |k| k.scan(/^\d+$/).any? ? k.to_i : k.to_s.to_sym }
  end

  def set_figures_hash(figures_hash, key_arr, val)
    key = key_arr.shift
    figures_hash[key] = {} unless figures_hash[key].is_a?(Hash)
    key_arr.length.positive? ? set_figures_hash(figures_hash[key], key_arr, val) : figures_hash[key] = val
  end

  def set_figures(figures_hash, type_number, product_id, market_id, values_hash)
    %i[order_count unit_price combined extra_cost].each do |key|
      set_figures_hash(figures_hash, [type_number, product_id, market_id, key], values_hash[key.to_s].to_f)
    end
  end

  def assign_figures(original_figures, parsed_figures)
    merged_figures = original_figures.deep_merge(parsed_figures)
    merged_figures.delete(0) if merged_figures[0]
    self.figures = compact_figures(merged_figures)
  end

  def empty_unit?(count_hash)
    count_hash[:order_count].zero? && count_hash[:unit_price].zero? if count_hash.keys.include?(:order_count)
  end

  def compact_figures(bloated_figures)
    bloated_figures.each_with_object({}) do |(k, v), h|
      if v.is_a?(Hash)
        ch = compact_figures(v)
        h[k] = ch unless ch.empty? || empty_unit?(ch)
      else
        h[k] = v
      end
    end
  end

  def autosave
    parsed_figures = {}
    original_figures = figures
    num_keys_to_integers(new_figures).each do |type_number, type_hash|
      type_hash.each do |product_id, product_hash|
        product_hash.each do |market_id, values_hash|
          set_figures(parsed_figures, type_number, product_id, market_id, values_hash)
        end
      end
    end
    assign_figures(original_figures, parsed_figures)
  end

  def add_sales(values_hash, market_record, product_record, accumulator_hash)
    unit_sales = values_hash[:unit_price] * values_hash[:order_count]
    product_count = product_record.count * product_record.multiplier
    sale = unit_sales * product_count * market_record.handling
    accumulator_hash[:sales] += sale unless sale.zero?
  end

  # Methods for calculating profits
  def add_costs(values_hash, market_record, product_record, accumulator_hash)
    ocount = values_hash[:order_count]
    product_cost = product_record.cost.to_f
    market_shipping = market_record.cost.to_f + market_record.block_cost.to_f
    accumulator_hash[:extras] += (ocount * market_record.optional_cost) unless values_hash[:extra_cost].zero?
    accumulator_hash[:extras] -= market_shipping unless values_hash[:combined].zero?
    accumulator_hash[:costs] += (ocount * product_cost) unless ocount.zero?
    accumulator_hash[:costs] += (ocount * market_shipping) unless market_record.brokerage || ocount.zero?
  end

  def add_daily_market_costs(accumulated_hash)
    # Add the daily costs for each market (money transfer and fax/data fees)
    accumulated_hash[:associated_markets].each do |market_id|
      market_record = Market.find(market_id)
      accumulated_hash[:extras] += market_record.one_time_cost.to_f
    end
  end

  def add_associations(accumulator_hash, product_id, market_id, values_hash)
    accumulator_hash[:associated_products] << product_id
    accumulator_hash[:associated_markets] << market_id
    add_last_activity_at(product_id, market_id, values_hash)
  end

  def add_last_activity_at(product_id, market_id, values_hash)
    return unless values_hash[:order_count].positive?

    join_record = ProductAndMarketJoin.find_by(product_id: product_id, market_id: market_id)
    join_record&.update(last_activity_at: Time.zone.now)
  end

  def assign_associations(accumulated_hash)
    self.product_ids = accumulated_hash[:associated_products]
    self.market_ids = accumulated_hash[:associated_markets]
  end

  def assign_totals(accumulated_hash)
    subtotals = { sales: accumulated_hash[:sales], expenses: accumulated_hash[:costs],
                  extras: accumulated_hash[:extras] }
    subtotals[:profits] = subtotals[:sales] - subtotals[:expenses] - subtotals[:extras]
    subtotals
  end

  def accumulate_data(accumulator_hash)
    figures.each do |_type_number, type_hash|
      type_hash.each do |product_id, product_hash|
        product_hash.each do |market_id, values_hash|
          product_record = Product.find(product_id)
          market_record = Market.find(market_id)
          add_associations(accumulator_hash, product_id, market_id, values_hash)
          add_sales(values_hash, market_record, product_record, accumulator_hash)
          add_costs(values_hash, market_record, product_record, accumulator_hash)
        end
      end
    end
  end

  # Old "quick" fix for automatically adding extra costs for certain products
  def sanbyaku_extra_cost_fix
    i = 0
    [8, 9, 23, 24].each do |id|
      extra_cost = figures.dig(1, 24, id, :extra_cost)
      figures[1][24][id][:extra_cost] = 1 if extra_cost&.zero?
      i += 1
    end
    save unless i.zero?
  end

  def calculate_tab
    sanbyaku_extra_cost_fix
    accumulator_hash = { associated_products: Set.new, associated_markets: Set.new, costs: 0, sales: 0, extras: 0 }
    # Accumulate Data
    unless figures[0]&.zero?
      accumulate_data(accumulator_hash)
      add_daily_market_costs(accumulator_hash)
      assign_associations(accumulator_hash)
    end
    self.totals = assign_totals(accumulator_hash)
  end

  # Section of methods for calculating volume data
  def setup_volumes_hash(accumulator_hash, type_number, product_id)
    accumulator_hash[:product_volumes][type_number] ||= { total: 0, count: 0 }
    accumulator_hash[:product_volumes][type_number][product_id] ||= { total: 0, count: 0 }
  end

  def accumulate_product_volume_data(accumulator_hash, type_number, product, multiplier, grams)
    subhash = accumulator_hash[:product_volumes][type_number][product.id]
    data = { name: product.namae, grams:, multiplier: }
    subhash.merge!(data) unless subhash.include?(data.keys.first)
  end

  def accumulate_product_volume_subtotals(accumulator_hash, type_number, product_id, products_sold, subtotal)
    subhash = accumulator_hash[:product_volumes][type_number]
    accumulator_hash[:total_sold] += products_sold
    subhash[:count] += products_sold
    subhash[product_id][:count] += products_sold
    accumulator_hash[:total_volume] += subtotal
    subhash[:total] += subtotal
    subhash[product_id][:total] += subtotal
  end

  def accumulate_product_market_volume_data(accumulator_hash, type_number, product_id, market, products_sold, subtotal)
    accumulator_hash[:product_volumes][type_number][product_id][market.mjsnumber] ||= {
      nick: market.nick,
      color: market.color,
      count: products_sold,
      id: market.id,
      total: 0
    }
    accumulator_hash[:product_volumes][type_number][product_id][market.mjsnumber][:total] + subtotal
  end

  def initial_market_hash(market)
    { nick: market.nick, color: market.color, id: market.id, count: 0, total: 0 }
  end

  def initial_product_hash(product, multiplier, grams, products_sold)
    { name: product.namae, grams:, count: products_sold, multiplier:, total: 0 }
  end

  def accumulate_market_volume_data(accumulator_hash, product, market, products_sold, subtotal, multiplier, grams)
    subhash = accumulator_hash[:market_volumes][market.mjsnumber]
    subhash ||= initial_market_hash(market)
    subhash[:count] += products_sold
    subhash[:total] += subtotal
    subhash[product.id] ||= initial_product_hash(product, multiplier, grams, products_sold)
    subhash[product.id][:total] += subtotal
  end

  def magic_number
    ENV['MAGIC_NUMBER'] ? (ENV['MAGIC_NUMBER']).to_f : 1
  end

  def intitial_volumes_accumulatory_hash
    { product_volumes: {}, market_volumes: {}, total_sold: 0, total_volume: 0, magic_number: }
  end

  def accumulate_product_data(accumulator_hash, type_number, product_id, product_hash)
    setup_volumes_hash(accumulator_hash, type_number, product_id)
    product = Product.find(product_id)
    grams = product.grams * (type_number == 3 ? 1 : accumulator_hash[:magic_number])
    multiplier = product.multiplier
    accumulate_product_volume_data(accumulator_hash, type_number, product, multiplier, grams)
    accumulate_market_data(accumulator_hash, product_hash, type_number, product, multiplier, grams)
  end

  def accumulate_market_data(accumulator_hash, product_hash, type_number, product, multiplier, grams)
    product_hash.each do |market_id, values_hash|
      products_sold = values_hash[:order_count] * product.count * multiplier
      subtotal = grams * products_sold
      accumulate_product_volume_subtotals(accumulator_hash, type_number, product.id, products_sold, subtotal)
      market = Market.find(market_id)
      accumulate_product_market_volume_data(accumulator_hash, type_number, product.id, market, products_sold, subtotal)
      accumulate_market_volume_data(accumulator_hash, product, market, products_sold, subtotal, multiplier, grams)
    end
  end

  def calculate_volumes
    accumulator_hash = intitial_volumes_accumulatory_hash
    unless figures[0]&.zero?
      figures.each do |type_number, type_hash|
        type_hash.each do |product_id, product_hash|
          accumulate_product_data(accumulator_hash, type_number, product_id, product_hash)
        end
      end
    end
    self.volumes = accumulator_hash
  end

  def recalculate_self
    calculate_tab
    self.subtotals = calc_subtotals
    save
  end

  def types_hash
    { '1' => 'トレイ', '2' => 'チューブ', '3' => '水切り', '4' => '殻付き', '5' => '冷凍', '6' => '単品' }
  end

  def setup_type_subtotals(subtotals_hash, type_id)
    init_hash = {
      type_name: types_hash[type_id.to_s],
      type_products_sold: 0,
      type_boxes_used: 0,
      type_expenses: 0,
      type_sales: 0

    }
    subtotals_hash[type_id.to_s] = init_hash unless subtotals_hash[type_id.to_s]
  end

  def setup_product_subtotals(subtotals_hash, type_id, product)
    init_hash = {
      product_name: product.namae,
      products_sold: 0,
      product_boxes_used: 0,
      product_expenses: 0,
      product_sales: 0
    }
    subtotals_hash[type_id.to_s][product.id.to_s] = init_hash unless subtotals_hash[type_id.to_s][product.id.to_s]
  end

  def assign_products_sold_subtotal(subtotals_hash, type_id, product_id, count, current_product)
    sold_value = count * current_product.count.to_f * current_product.multiplier.to_f
    subtotals_hash[type_id.to_s][:type_products_sold] += sold_value
    subtotals_hash[:total_products_sold] += sold_value
    subtotals_hash[type_id.to_s][product_id.to_s][:products_sold] += sold_value
  end

  def assign_boxes_count_subtotal(subtotals_hash, type_id, product, count)
    boxes_used = count * product.multiplier
    subtotals_hash[:total_boxes_used] += boxes_used
    subtotals_hash[type_id.to_s][:type_boxes_used] += boxes_used
    subtotals_hash[type_id.to_s][product.id.to_s][:product_boxes_used] += boxes_used
  end

  def assign_expenses_subotal(subtotals_hash, type_id, product, market, count)
    base_expense = market.cost + market.block_cost + product.cost
    expenses = market.brokerage ? count * product.cost : count * base_expense
    subtotals_hash[type_id.to_s][:type_expenses] += expenses
    subtotals_hash[type_id.to_s][product.id.to_s][:product_expenses] += expenses
  end

  def assign_sales_subotal(subtotals_hash, type_id, product, market, count, price)
    unit_multiplier = product.count * product.multiplier
    sales = (price * count * unit_multiplier) * market.handling
    subtotals_hash[type_id.to_s][:type_sales] += sales
    subtotals_hash[type_id.to_s][product.id.to_s][:product_sales] += sales
  end

  def assign_special_costs(subtotals_hash, market_id, count, combined, extra_cost)
    subtotals_hash[:extra_costs][market_id.to_s] ||= { awase_count: 0, extra_costs_count: 0 }
    subtotals_hash[:extra_costs][market_id.to_s][:awase_count] += combined.to_f
    subtotals_hash[:extra_costs][market_id.to_s][:extra_costs_count] += extra_cost.to_f * count
  end

  def accumulate_subtotals(subtotals_hash, type_id, product_id, market_id, value_hash)
    current_product = Product.find_by(id: product_id)
    current_market = Market.find_by(id: market_id)
    setup_product_subtotals(subtotals_hash, type_id, current_product)
    count = value_hash[:order_count]
    assign_products_sold_subtotal(subtotals_hash, type_id, product_id, count, current_product)
    assign_boxes_count_subtotal(subtotals_hash, type_id, current_product, count)
    assign_expenses_subotal(subtotals_hash, type_id, current_product, current_market, count)
    assign_sales_subotal(subtotals_hash, type_id, current_product, current_market, count, value_hash[:unit_price])
    assign_special_costs(subtotals_hash, market_id, count, value_hash[:combined], value_hash[:extra_cost])
  end

  def init_subtotals
    { total_products_sold: 0, total_boxes_used: 0, extra_costs: {} }
  end

  def calc_subtotals
    subtotals_hash = init_subtotals
    figures.each do |type_id, product_hash|
      next if type_id.zero?

      setup_type_subtotals(subtotals_hash, type_id)
      product_hash.each do |product_id, market_hash|
        market_hash.each do |market_id, value_hash|
          accumulate_subtotals(subtotals_hash, type_id, product_id, market_id, value_hash)
        end
      end
    end
    subtotals_hash
  end

  def kilo_sales_estimate
    return 0 unless volumes&.fetch(:total_volume, 0)&.positive?

    (totals[:profits] / (volumes[:total_volume] / 1000)).round(0)
  end

  def predict_profit
    last_week_finished_profit = find_finished_profits(date - 7.days, date)
    prior_year_same_week_finished_profit = find_finished_profits(date - 372.days, date - 1.year)
    prior_year_finished_profit = find_finished_profits(date - 1.year, date - 1.year + 7.days)
    return unless last_week_finished_profit && prior_year_same_week_finished_profit && prior_year_finished_profit

    kilo_sales_percent_change_estimate = (prior_year_finished_profit.kilo_sales_estimate.to_f / prior_year_same_week_finished_profit.kilo_sales_estimate.to_f)
    predicted_kilo_sales_estimate = last_week_finished_profit.kilo_sales_estimate.to_f * kilo_sales_percent_change_estimate
    predicted_profit = predicted_kilo_sales_estimate * volumes[:total_volume]

    totals[:last_week_basis_kilo_sales_estimate] = last_week_finished_profit.kilo_sales_estimate
    totals[:predicted_kilo_sales_percent_change_estimate] = kilo_sales_percent_change_estimate
    totals[:predicted_kilo_sales_estimate] = predicted_kilo_sales_estimate
    totals[:predicted_profit] = predicted_profit
  end

  def find_finished_profits(start_date, end_date)
    profits = Profit.where(date: start_date..end_date).order(date: :desc)
    profits.detect { |supply| supply.check_completion[0].zero? && supply.kilo_sales_estimate.positive? }
  end

  def assign_subtotals
    self.subtotals = figures[0]&.zero? ? init_subtotals : calc_subtotals
  end

  def assign_date
    self.date = from_nengapi(sales_date)
  end

  def process_update
    calculate_tab
    calculate_volumes
    assign_subtotals
    set_completion
    assign_date
    predict_profit
  end
end
