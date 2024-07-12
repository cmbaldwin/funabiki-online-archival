class OysterSupply < ApplicationRecord
  self.primary_key = :id
  belongs_to :stat, optional: true
  has_one :oyster_invoices_supply, dependent: :destroy
  has_one :oyster_invoice, through: :oyster_invoices_supply, validate: false

  validates :supply_date, presence: true
  validates :date, presence: true
  validates :date, uniqueness: true
  serialize :oysters, type: Hash
  serialize :totals, type: Hash

  after_initialize :assure_date
  before_save :set_totals

  attr_accessor :location, :start_date, :end_date, :export_format, :password

  scope :with_date, ->(dates) { where(date: [dates]) }

  include OrderQuery
  order_query :oyster_supply_query,
              [:supply_date] # Sort :supply_date in :desc order
  delegate :previous, to: :oyster_supply_query
  delegate :next, to: :oyster_supply_query

  # Used in Profit associations
  def mushiage_total
    oysters['okayama']['mushiage']['subtotal'].to_f
  end

  # Initialize
  def assure_date
    self.supply_date = date.strftime('%Y年%m月%d日') unless supply_date
    self.date = parsed_date unless date_assigned
  end

  def parsed_date
    DateTime.strptime(supply_date, '%Y年%m月%d日')
  end

  def date_assigned
    date == parsed_date
  end

  # Various variables
  def locked?
    !oyster_invoice.nil?
  end

  def okayama_keys
    %i[hinase tamatsu iri mushiage]
  end

  def okayama_key_str
    { hinase: '日生', tamatsu: '玉津', iri: '伊里', mushiage: '虫明' }
  end

  def weekday_japanese(num)
    # d.strftime("%w") to Japanese
    weekdays = { 0 => '日', 1 => '月', 2 => '火', 3 => '水', 4 => '木', 5 => '金', 6 => '土' }
    weekdays[num]
  end

  def type_to_japanese(type)
    {
      'large' => 'むき身（大）',
      'small' => 'むき身（小）',
      'eggy' => 'むき身（卵）',
      'large_shells' => '殻付き（大）',
      'small_shells' => '殻付き（小）',
      'thin_shells' => '殻付き（バラ）',
      'small_triploid_shells_small' => '殻付き（三倍体 M）',
      'triploid_shells' => '殻付き（三倍体 L）',
      'large_triploid_shells_large' => '殻付き（三倍体 LL）',
      'xl_triploid_shells' => '殻付き（三倍体 LLL）'
    }[type]
  end

  def type_to_unit(type)
    { 'large' => 'kg',
      'small' => 'kg',
      'eggy' => 'kg',
      'large_shells' => '個',
      'small_shells' => '個',
      'thin_shells' => 'kg',
      'small_triploid_shells' => '個',
      'triploid_shells' => '個',
      'large_triploid_shells' => '個',
      'xl_triploid_shells' => '個' }[type]
  end

  def kanji_am_pm(am_or_pm)
    { 'am' => '午前', 'pm' => '午後', '午前' => 'am', '午後' => 'pm' }[am_or_pm]
  end

  def tamatsu_farmer_numbers
    oysters['okayama']['tamatsu'].keys.select { |k| k.to_i.positive? }
  end

  def okayama_total
    total = 0
    %w[hinase tamatsu iri mushiage].each do |location|
      total += oysters['okayama'][location]['subtotal'].to_f unless oysters['okayama'].nil?
    end
    total
  end

  def number_to_circular(num)
    int = num.to_i
    return unless int.positive? && int < 20

    (9312..9331).map { |i| i.chr(Encoding::UTF_8) }[int - 1]
  end

  def other_types
    %w[大 中 小]
  end

  def other_total
    # "other" => {
    #   "0" => {
    #           "name" => "マルト水産1",
    #       "location" => "相生1",
    #              "大" => "1",
    #              "中" => "1",
    #              "小" => "1"
    #   }
    other_data = oysters['other']
    total = other_types.map do |type|
      other_data&.compact&.map { |_number, data| data[type]&.to_i }&.compact
    end
    total.compact.flatten.sum
  end

  def acquire_location(supplier_id)
    return @supplier_hash[supplier_id] if @supplier_hash.keys.include?(supplier_id)

    location = Supplier.find(supplier_id).location
    @supplier_hash[supplier_id] = location
    location
  end

  def init_shucked_subtotals(type, location)
    @volume_subtotals[type] ||= {}
    @cost_subtotals[type] ||= {}
    @volume_subtotals[type][location] ||= 0
    @cost_subtotals[type][location] ||= 0
  end

  def accum_shucked_subtotals(type, supplier_id, amounts)
    location = acquire_location(supplier_id)
    init_shucked_subtotals(type, location)
    @volume_subtotals[type][location] += amounts['volume'].to_f
    @cost_subtotals[type][location] += amounts['invoice'].to_f
  end

  def shucked_subtotals
    @volume_subtotals = {}
    @cost_subtotals = {}
    @supplier_hash = {}
    %w[large small eggy damaged].each do |type|
      oysters[type].each do |supplier_id, amounts|
        accum_shucked_subtotals(type, supplier_id, amounts)
      end
    end
  end

  def supplier_totals(sup_num)
    set_types
    @types.each_with_object({}) do |type, accumulator|
      data = oysters[type][sup_num]
      next unless data['volume'].to_f.positive?

      accumulator[type] = data
    end
  end

  def includes_supplier?(sup_num)
    !supplier_totals(sup_num).empty?
  end

  def hyogo_large_shucked_total
    total = 0
    oysters['large'].each do |_supplier, amounts|
      total += amounts['volume'].to_f
    end
    total
  end

  def hyogo_small_shucked_total
    total = 0
    oysters['small'].each do |_supplier, amounts|
      total += amounts['volume'].to_f
    end
    total
  end

  def hyogo_small_shucked_eggy_total
    total = 0
    oysters['eggy'].each do |_supplier, amounts|
      total += amounts['volume'].to_f
    end
    total
  end

  def hyogo_small_shucked_damaged_total
    total = 0
    oysters['damaged'].each do |_supplier, amounts|
      total += amounts['volume'].to_f
    end
    total
  end

  def hyogo_mukimi_total
    grda = hyogo_large_shucked_total + hyogo_small_shucked_total
    grdb = hyogo_small_shucked_eggy_total + hyogo_small_shucked_damaged_total
    grda + grdb
  end

  def mukimi_total
    othr = okayama_total + other_total
    hyogo_mukimi_total + othr
  end

  def hyogo_thin_shells_total
    total = 0
    oysters['thin_shells'].each do |_supplier, amounts|
      total += amounts['volume'].to_f
    end
    total
  end

  def shells_total
    total = 0
    %w[large_shells small_shells small_triploid_shells triploid_shells large_triploid_shells xl_triploid_shells].each do |type|
      oysters[type]&.each do |_supplier, amounts|
        total += amounts['volume'].to_f
      end
    end
    total
  end

  def set_variables
    @sakoshi_suppliers = Supplier.where(location: '坂越').order(:supplier_number)
    @aioi_suppliers = Supplier.where(location: '相生').order(:supplier_number)
    @all_suppliers = @sakoshi_suppliers + @aioi_suppliers
    @receiving_times = %w[am pm]
    set_types
    @supplier_numbers = @sakoshi_suppliers.pluck(:id).map(&:to_s)
    @supplier_numbers += @aioi_suppliers.pluck(:id).map(&:to_s)
  end

  def set_types
    @types = %w[large small eggy damaged large_shells small_shells thin_shells small_triploid_shells triploid_shells
                large_triploid_shells xl_triploid_shells]
  end

  # Begin totals accumulation and calculation data functions
  def cost_total
    hyogo_mukimi_cost_total + okayama_mukimi_cost_total + other_cost_total
  end

  def big_shell_avg_cost
    cost_total = 0
    shells_count = 0
    oysters['large_shells'].each do |_supplier, amounts|
      cost_total += amounts['invoice'].to_f
      shells_count += amounts['volume'].to_f
    end
    return 0.0 if shells_count.zero?

    cost_total / shells_count
  end

  def hyogo_mukimi_cost_total
    set_variables
    total = 0
    %w[large small eggy damaged].each do |type|
      @supplier_numbers.each do |id|
        total += oysters[type].dig(id, 'invoice').to_f || 0
      end
    end
    total
  end

  def okayama_mukimi_cost_total
    total = 0
    %w[hinase tamatsu iri mushiage].each do |location|
      next if oysters['okayama'].nil?

      total += oysters['okayama'][location]['invoice'].to_f
    end
    total
  end

  def other_cost_total
    other_data = oysters['other']
    total = other_data&.map do |_number, data|
      data['invoice']&.to_f
    end
    total&.compact&.flatten&.sum.to_f
  end

  def accumulate_shell_totals(new_totals)
    new_totals[:shell_total] = shells_total
    new_totals[:big_shell_avg_cost] = big_shell_avg_cost
  end

  def hyogo_key_str(locale_str)
    { 'sakoshi' => '坂越', 'aioi' => '相生' }[locale_str]
  end

  def accumulate_hyogo_volume(locale_str, new_totals)
    volume_total = 0
    japanese_str = hyogo_key_str(locale_str)
    %w[large small eggy damaged].each do |type|
      vol = @volume_subtotals[type][japanese_str]
      new_totals[:"#{locale_str}_#{type}_volume"] = vol
      volume_total += vol
    end
    new_totals[:"#{locale_str}_muki_volume"] = volume_total
  end

  def accumulate_hyogo_cost(locale_str, new_totals)
    volume_total = 0
    japanese_str = hyogo_key_str(locale_str)
    %w[large small eggy damaged].each do |type|
      cost = @cost_subtotals[type][japanese_str]
      new_totals[:"#{locale_str}_#{type}_cost"] = cost
      volume_total += cost
    end
    new_totals[:"#{locale_str}_muki_cost"] = volume_total
  end

  def accumulate_hyogo_avgs(locale_str, new_totals)
    cost = new_totals[:"#{locale_str}_muki_cost"]
    volume = new_totals[:"#{locale_str}_muki_volume"]
    new_totals[:"#{locale_str}_avg_kilo"] = volume.zero? ? 0.0 : (cost / volume)
  end

  def accumulate_hyogo_subtotals(new_totals)
    %w[sakoshi aioi].each do |locale_str|
      accumulate_hyogo_volume(locale_str, new_totals)
      accumulate_hyogo_cost(locale_str, new_totals)
      accumulate_hyogo_avgs(locale_str, new_totals)
    end
  end

  def accumulate_hyogo_totals(new_totals)
    new_totals[:hyogo_total] = hyogo_mukimi_total
    new_totals[:hyogo_mukimi_cost_total] = hyogo_mukimi_cost_total
    new_totals[:hyogo_avg_kilo] = new_totals[:hyogo_mukimi_cost_total] / new_totals[:hyogo_total] unless new_totals[:hyogo_total].zero?
    new_totals[:hyogo_avg_kilo] ||= 0.0
  end

  def accumulate_okayama_totals(new_totals)
    subtotal = okayama_total
    new_totals[:okayama_total] = subtotal
    new_totals[:okayama_mukimi_cost_total] = okayama_mukimi_cost_total
    new_totals[:okayama_avg_kilo] = new_totals[:okayama_mukimi_cost_total] / subtotal unless subtotal.zero?
    new_totals[:okayama_avg_kilo] ||= 0.0
  end

  def accumulate_other_totals(new_totals)
    new_totals[:other_total] = other_total
    new_totals[:other_cost_total] = other_cost_total
    new_totals[:other_avg_kilo] = new_totals[:other_cost_total] / new_totals[:other_total] unless new_totals[:other_total].zero?
    new_totals[:other_avg_kilo] ||= 0.0
  end

  def accumulate_totals(new_totals)
    new_totals[:mukimi_total] = new_totals[:hyogo_total] + new_totals[:okayama_total] + new_totals[:other_total]
    new_totals[:cost_total] = cost_total
    new_totals[:total_kilo_avg] = new_totals[:cost_total] / new_totals[:mukimi_total] unless new_totals[:mukimi_total].zero?
    new_totals[:total_kilo_avg] ||= 0.0
  end

  def predict_costs(new_totals)
    last_week_finished_supply = find_finished_supplies(date - 7.days, date)
    prior_year_same_week_finished_supply = find_finished_supplies(date - 1.year - 7.days, date - 1.year)
    prior_year_finished_supply = find_finished_supplies(date - 1.year, date - 1.year + 1.day)
    return unless last_week_finished_supply && prior_year_same_week_finished_supply && prior_year_finished_supply

    percent_change = calculate_percent_change(last_week_finished_supply.totals[:total_kilo_avg], prior_year_same_week_finished_supply.totals[:total_kilo_avg])
    predicted_cost = extrapolate_cost(prior_year_finished_supply.totals[:total_kilo_avg], percent_change)

    new_totals[:last_year_kilo_total_avg] = prior_year_finished_supply.totals[:total_kilo_avg]
    new_totals[:predicted_percent_change] = percent_change
    new_totals[:predicted_cost] = predicted_cost
  end

  def find_finished_supplies(start_date, end_date)
    supplies = OysterSupply.where(date: start_date..end_date)
    supplies.detect { |supply| supply.check_completion.empty? && supply.totals[:total_kilo_avg].positive? }
  end

  def calculate_percent_change(last_week, prior_year_same_week)
    (last_week - prior_year_same_week) / prior_year_same_week.to_f
  end

  def extrapolate_cost(prior_year, percent_change)
    prior_year * (1 + percent_change)
  end

  def set_totals
    return if oysters.empty?

    shucked_subtotals
    new_totals = {}
    accumulate_shell_totals(new_totals)
    accumulate_hyogo_subtotals(new_totals)
    accumulate_hyogo_totals(new_totals)
    accumulate_okayama_totals(new_totals)
    accumulate_other_totals(new_totals)
    accumulate_totals(new_totals)
    predict_costs(new_totals)
    self.totals = new_totals
  end

  # Begin price entry completion check functions
  def init_completion
    set_types
    @types.each do |type|
      oysters[type] ||= {}
      oysters[type].each do |supplier_id, supply_hash|
        if (supply_hash['volume']) != '0' && (supply_hash['price'] == '0')
          @completion[type] ||= []
          @completion[type] << supplier_id
        end
      end
    end
  end

  def add_completion(str, subtotal, no_price)
    subtotal = subtotal.to_f.positive?
    no_price = no_price.to_f.zero?
    @completion['okayama'] << str if subtotal && no_price
  end

  def okayama_unfinished?(locale_str)
    @completion['okayama'] ||= []
    subtotal = oysters['okayama'][locale_str]['subtotal']
    no_price = oysters['okayama'][locale_str]['price']
    add_completion(locale_str, subtotal, no_price)
  end

  def tamatsu_subtotal(sup_hash)
    %w[小 大].map { |typ| sup_hash[typ].to_f }.sum
  end

  def tamatsu_unfinished?
    return unless oysters['okayama']['tamatsu']['subtotal'].to_f.positive?

    oysters['okayama']['tamatsu'].each do |_sup_num, sup_hash|
      next unless sup_hash.is_a?(Hash)

      subtotal = tamatsu_subtotal(sup_hash)
      no_price = sup_hash['price']
      add_completion('tamatsu', subtotal, no_price)
    end
  end

  def mushiage_unfinished?
    return unless oysters['okayama']['mushiage']['subtotal'].to_f.positive?

    oysters['okayama']['mushiage'].each do |_sup_num, sup_hash|
      next unless sup_hash.is_a?(Hash)

      subtotal = sup_hash['volume']
      no_price = sup_hash['price']
      add_completion('mushiage', subtotal, no_price)
    end
  end

  def check_completion
    @completion = {}
    init_completion
    %w[hinase iri].each { |locale_str| okayama_unfinished?(locale_str) }
    tamatsu_unfinished?
    mushiage_unfinished?
    return @completion unless @completion['okayama']

    @completion.delete('okayama') if @completion['okayama'].empty?
    @completion
  end

  # Begin price entry error detection functions
  def supplier_volume(sup_hash)
    sup_hash['volume'].to_f.positive?
  end

  def strange_price(last_price, current_price)
    diff_price = current_price != last_price
    wild_price = (current_price < last_price * 0.8) || (current_price > last_price * 1.2)

    diff_price && wild_price
  end

  def init_error(sup_id, type)
    @errors[sup_id] ||= {}
    @errors[sup_id][type] = {}
  end

  def add_error(sup_id, type, last_price, current_price)
    init_error(sup_id, type)
    @errors[sup_id][type]['previous_price'] = last_price
    @errors[sup_id][type]['current_price'] = current_price
    @errors[sup_id][type]['should not be less than'] = last_price * 0.8
    @errors[sup_id][type]['should not be more than'] = last_price * 1.2
  end

  def previous_data
    oyster_supply_query.previous.year_to_date
  end

  def last_price(sup_id, type)
    @prev[sup_id][type]['price'].sort.reverse.last.to_f
  end

  def process_errors
    @types.each do |type|
      oysters[type].each do |sup_id, sup_hash|
        next unless supplier_volume(sup_hash)

        last_price = last_price(sup_id, type)
        current_price = sup_hash['price'].to_f
        next unless strange_price(last_price, current_price)

        add_error(sup_id, type, last_price, current_price)
      end
    end
  end

  def check_errors
    set_variables
    @errors = {}
    @prev = previous_data
    process_errors
    @errors
  end

  # Begin new model initilization functions
  def init_oysters_hash
    @receiving_times.each do |time|
      oysters[time] ||= {}
      @types.each do |type|
        oysters[time][type] ||= {}
        @supplier_numbers.each do |sup_num|
          oysters[time][type][sup_num] ||= {}
          setup_oysters_inputs(time, type, sup_num)
        end
      end
    end
  end

  def setup_oyster_cells(position, cell_num)
    cell_num.times do |i|
      position[i.to_s] ||= 0
    end
  end

  def setup_oyster_subtotals(type, sup_num)
    oysters[type] ||= {}
    oysters[type][sup_num] ||= {}
    sub_position = oysters[type][sup_num]
    sub_position['volume'] ||= 0
    sub_position['price'] ||= 0
    sub_position['invoice'] ||= 0
  end

  def setup_oysters_inputs(time, type, sup_num)
    position = oysters[time][type][sup_num]
    if (type == 'large') || (type == 'small')
      setup_oyster_cells(position, 6)
    else # kizu, ran, etc
      position['0'] ||= 0
    end
    position['subtotal'] ||= 0
    setup_oyster_subtotals(type, sup_num)
  end

  def setup_okayama_subtotals(locale_str)
    position = oysters['okayama'][locale_str]
    position['subtotal'] ||= 0
    position['price'] ||= 0
    position['invoice'] ||= 0
  end

  def setup_hinase
    oysters['okayama']['hinase'] ||= {}
    %w[大 中 小].each do |type|
      oysters['okayama']['hinase'][type] ||= 0
    end
    setup_okayama_subtotals('hinase')
  end

  def iri_cell_setup(num)
    oysters['okayama']['iri'][num] ||= {}
    oysters['okayama']['iri'][num]['volume'] ||= 0
    oysters['okayama']['iri'][num]['price'] ||= 0
  end

  def setup_iri
    oysters['okayama']['iri'] ||= {}
    %w[1 2 7 15 38].each do |num|
      iri_cell_setup(num)
    end
    setup_okayama_subtotals('iri')
  end

  def tamatsu_cell_setup
    {
      '大' => 0,
      '小' => 0,
      'volume' => 0,
      'price' => 0
    }
  end

  def setup_tamatsu
    oysters['okayama']['tamatsu'] ||= {}
    %w[1 2 4 5].each do |num|
      oysters['okayama']['tamatsu'][num] ||= tamatsu_cell_setup
    end
    oysters['okayama']['tamatsu']['small_price'] ||= 0
    setup_okayama_subtotals('tamatsu')
  end

  def setup_mushiage
    oysters['okayama']['mushiage'] ||= {
      'subtotal' => 0,
      'invoice' => 0
    }
    15.times do |t|
      oysters['okayama']['mushiage'][t.to_s] ||= { 'volume' => 0, 'price' => 0 }
    end
  end

  def okayama_setup
    # Hinase by size, single daily price
    oysters['okayama'] ||= {}
    setup_hinase
    setup_iri
    setup_tamatsu
    setup_mushiage
  end

  def other_setup
    oysters['other'] = {}
  end

  def do_setup
    set_variables
    oysters ||= {}
    oysters['tax'] ||= '1.08'
    init_oysters_hash
    okayama_setup
    other_setup
  end

  # Begin Year to Date data functions
  def dated_record_ytd_range
    return unless date.month >= 10

    @start_year = date.year
    @end_year = (date + 1.year).year
  end

  def undated_record_ytd_range
    @start_year = Time.zone.today.year
    @end_year = (Time.zone.today + 1.year).year
  end

  def adjust_ytd_range_endpoints
    if date
      @start_year = (date - 1.year).year
      @end_year = date.year
      dated_record_ytd_range
    elsif Time.zone.today.month.to_i >= 10
      undated_record_ytd_range
    end
  end

  def year_to_date_range
    @start_year ||= (Time.zone.today - 1.year).year
    @end_year ||= Time.zone.today.year
    adjust_ytd_range_endpoints
    season_start_date = Date.new(@start_year, 10, 1)
    season_end_date = Date.new(@end_year, 9, 30)
    return season_start_date..date if date

    season_start_date..season_end_date
  end

  def accumulate_ytd_data(oyster_supply)
    @types.each do |type|
      oyster_supply.oysters[type]&.each do |supplier_id, totals|
        @new_ytd[supplier_id] ||= {}
        @new_ytd[supplier_id][type] ||= { price: [], volume: 0, invoice: 0 }
        accumulate_supplier_data(supplier_id, type, totals['price'].to_f, totals['volume'].to_f, totals['invoice'].to_f)
      end
    end
  end

  def accumulate_supplier_data(supplier_id, type, price, volume, invoice)
    return unless @new_ytd.dig(supplier_id, type)

    position = @new_ytd[supplier_id][type]
    position[:price] << price if price.positive?

    position[:volume] += volume
    position[:invoice] += invoice
  end

  def calculate_ytd
    set_types
    # Calculate record
    @new_ytd = { updated: DateTime.now }
    year_to_date_range.each do |date|
      oyster_supply = OysterSupply.find_by(date:)
      next unless oyster_supply

      accumulate_ytd_data(oyster_supply)
    end
    @new_ytd
  end

  def last_ytd_update
    return if oysters_last_update.is_a?(DateTime)

    self.oysters_last_update = updated_at
    save
    oysters_last_update
  end

  def year_to_date
    oysters[:year_to_date] = calculate_ytd
    last_ytd_update
    oysters[:year_to_date]
  end

  # Begin Oyster Data Functions (for Invoices)
  def supplier_location_hash(sup_id)
    @supplier_hash ||= {}
    return @supplier_hash[sup_id] if @supplier_hash[sup_id]

    location = Supplier.find_by(id: sup_id.to_i)&.location
    location ||= '坂越'
    @supplier_hash[sup_id] = location
    supplier_location_hash(sup_id)
  end

  def accumulate_oyster_price_data(location, type, price, volume)
    @accumulator[location][type][price] ||= 0
    @accumulator[location][type][price] += volume
    @accumulator[location][:total] += (price.to_f * volume)
  end

  def accumulate_oyster_volume_data(location, type, volume)
    @accumulator[location][:volume_total] ||= {}
    @accumulator[location][:volume_total][type] ||= 0
    @accumulator[location][:volume_total][type] += volume
  end

  def accumulate_vol_price_subtotal_data(location, type, price, volume)
    @accumulator[location][:price_type_total] ||= {}
    @accumulator[location][:price_type_total][type] ||= 0
    @accumulator[location][:price_type_total][type] += (price * volume)
  end

  def accumulate_oyster_data(sup_id, type, values)
    location = supplier_location_hash(sup_id)
    @accumulator[location] ||= {}
    @accumulator[location][:total] ||= 0
    @accumulator[location][type] ||= {}
    price = values['price'].to_f
    volume = values['volume'].to_f
    # List volumes by price
    accumulate_oyster_price_data(location, type, price, volume)
    # Volume subtotal by type
    accumulate_oyster_volume_data(location, type, volume)
    # Volume price subtotal by type
    accumulate_vol_price_subtotal_data(location, type, price, volume)
  end

  def data_accumulator_adjustments
    @accumulator.each_key do |location|
      @accumulator[location][:tax] = (@accumulator[location][:total] * 0.08).to_f
      @accumulator[location][:total].to_f
    end
  end

  def oyster_data
    set_types
    @accumulator = {}
    @types.each do |type|
      oysters[type].each do |sup_id, values|
        accumulate_oyster_data(sup_id, type, values)
      end
    end
    data_accumulator_adjustments
    @accumulator
  end

  def init_hyogo_alteration(altered, type)
    return if altered.dig(id, type)

    altered[id] ||= {}
    altered[id]['hyogo'] ||= {}
    altered[id]['hyogo'][type] ||= {}
  end

  # Begin price setting tool functions
  def record_hyogo_alteration(altered, type, price, supplier_id)
    altered[id]['hyogo'][type][price] ||= []
    altered[id]['hyogo'][type][price] << supplier_id
  end

  def record_hyogo_price(altered, type, price, supplier_id)
    init_hyogo_alteration(altered, type)
    volume = @new_hash.dig(type, supplier_id, 'volume').to_f
    return if volume.zero?

    @new_hash[type][supplier_id]['price'] = price
    @new_hash[type][supplier_id]['invoice'] = (price.to_f * volume).to_s
    record_hyogo_alteration(altered, type, price, supplier_id)
  end

  def set_hyogo_prices(price_set_hash, altered)
    price_set_hash.each do |_i, price_hash|
      suppliers = price_hash['ids'].reject(&:empty?)
      next if suppliers.empty?

      price_hash['prices'].each do |type, price|
        next if price.empty?

        suppliers.each do |supplier_id|
          record_hyogo_price(altered, type, price, supplier_id)
        end
      end
    end
  end

  def record_hinase_alteration(altered, price)
    altered[id] ||= {}
    altered[id]['okayama'] ||= {}
    altered[id]['okayama']['hinase'] = price
  end

  def record_hinase_price_invoice(subtotal, price)
    @new_hash['okayama']['hinase']['price'] = price.to_s
    @new_hash['okayama']['hinase']['invoice'] = (subtotal * price).to_s
  end

  def record_hinase_prices(altered, price_set_hash)
    subtotal = oysters['okayama']['hinase']['subtotal'].to_f
    price = price_set_hash['hinase'].to_f
    return unless subtotal.positive? && price.positive?

    record_hinase_price_invoice(subtotal, price)
    record_hinase_alteration(altered, price)
  end

  def iri_position
    @new_hash['okayama']['iri']
  end

  def record_iri_alteration(altered, sup_num, price)
    return unless price.to_f.positive?

    altered[id] ||= {}
    altered[id]['okayama'] ||= {}
    altered[id]['okayama']['iri'] ||= {}
    altered[id]['okayama']['iri'][sup_num] = price
  end

  def iteration_standard_iri_prices(altered, all_price)
    iri_position.each do |k, vh| # Iterate farmers
      volume = vh['volume'].to_f
      next unless k.to_f.positive? && volume.positive?

      vh['price'] = all_price.to_f # Set standard price set for farmer
      record_iri_alteration(altered, k, all_price)
      @iri_accumulator[:volume_total] += volume
      @iri_accumulator[:invoice_total] += volume * all_price.to_f
    end
  end

  def alter_iri_subtotals
    iri_position['subtotal'] = @iri_accumulator[:volume_total].to_s
    iri_position['invoice'] = @iri_accumulator[:invoice_total].to_s
    price = @iri_accumulator[:volume_total] / @iri_accumulator[:invoice_total]
    iri_position['price'] = price.to_s
  end

  def record_standard_iri_prices(altered, price_set_hash)
    return unless iri_position['subtotal'].to_f.positive?

    all_price = price_set_hash['iri']['all'] # Standard price
    @iri_accumulator = { volume_total: 0, invoice_total: 0 }
    iteration_standard_iri_prices(altered, all_price)
    alter_iri_subtotals
  end

  def record_indiv_iri_price(sup_num, price, altered)
    volume = iri_position[sup_num]['volume']
    return unless volume.to_f.positive?

    iri_position[sup_num]['price'] = price
    record_iri_alteration(altered, sup_num, price)
    @iri_accumulator[:volume_total] += volume.to_f
    @iri_accumulator[:invoice_total] += volume.to_f * price.to_f
  end

  def set_indiv_iri_prices(altered, price_set_hash)
    @iri_accumulator = { volume_total: 0, invoice_total: 0 }
    price_set_hash['iri'].each do |sup_num, price|
      next unless sup_num.to_f.positive?

      record_indiv_iri_price(sup_num, price, altered)
    end
    alter_iri_subtotals
  end

  def iri_has_subtotal
    oysters['okayama']['iri']['subtotal'].to_f.positive?
  end

  def iri_has_new_prices(price_set_hash)
    price_set_hash['iri'].values.map(&:to_f).sum.positive?
  end

  def set_iri_prices(altered, price_set_hash)
    return unless iri_has_subtotal && iri_has_new_prices(price_set_hash)

    if price_set_hash['iri']['all'].to_f.positive?
      record_standard_iri_prices(altered, price_set_hash)
    else
      set_indiv_iri_prices(altered, price_set_hash)
    end
  end

  def init_tamatsu_alterations(altered)
    altered[id] ||= {}
    altered[id]['okayama'] ||= {}
    altered[id]['okayama']['tamatsu'] ||= {}
  end

  def record_tamatsu_alteration(altered, size_str, price, sup_num = nil)
    init_tamatsu_alterations(altered)
    position = altered[id]['okayama']['tamatsu']
    if sup_num
      position[sup_num] ||= {}
      position[sup_num][size_str] = price
    else
      position[size_str] = price
    end
  end

  def record_tamatsu_small_prices(altered, price_set_hash)
    all_small_price = price_set_hash['tamatsu']['all']['small']
    return unless all_small_price.to_f.positive?

    @new_hash['okayama']['tamatsu']['small_price'] = all_small_price
    record_tamatsu_alteration(altered, 'small', all_small_price)
  end

  def record_tamatsu_large_price(sup_num, price)
    @new_hash['okayama']['tamatsu'][sup_num]['price'] = price
  end

  def set_tamatsu_large_prices(altered, price_set_hash, farmer_numbers)
    all_large_price = price_set_hash['tamatsu']['all']['large']
    farmer_numbers.each do |sup_num|
      price = price_set_hash['tamatsu'][sup_num]['large']
      price = all_large_price if all_large_price.to_f.positive?
      next unless price.to_f.positive?

      record_tamatsu_large_price(sup_num, price)
      record_tamatsu_alteration(altered, 'large', price, sup_num)
    end
  end

  def tamatsu_large_price_invoice(farmer_numbers)
    invoice = farmer_numbers.map do |num|
      position = @new_hash['okayama']['tamatsu']
      volume = position[num]['大'].to_f
      price = position[num]['price'].to_f
      volume * price
    end
    invoice.sum
  end

  def tamatsu_small_price_invoice(farmer_numbers)
    invoice = farmer_numbers.map do |num|
      position = @new_hash['okayama']['tamatsu']
      volume = position[num]['小'].to_f
      price = position['small_price'].to_f
      volume * price
    end
    invoice.sum
  end

  def record_tamatsu_totals(farmer_numbers)
    large_invoice = tamatsu_large_price_invoice(farmer_numbers)
    small_invoice = tamatsu_small_price_invoice(farmer_numbers)
    invoice_total = large_invoice + small_invoice
    position = @new_hash['okayama']['tamatsu']
    position['invoice'] = invoice_total.to_s
    invoice_subtotal = @new_hash['okayama']['tamatsu']['subtotal'].to_f
    position['price'] = (invoice_total.to_f / invoice_subtotal).to_s
  end

  def set_tamatsu_prices(altered, price_set_hash)
    return unless oysters['okayama']['tamatsu']['subtotal'].to_f.positive?

    farmer_numbers = tamatsu_farmer_numbers
    record_tamatsu_small_prices(altered, price_set_hash)
    set_tamatsu_large_prices(altered, price_set_hash, farmer_numbers)
    record_tamatsu_totals(farmer_numbers)
  end

  def set_okayama_prices(price_set_hash, altered)
    record_hinase_prices(altered, price_set_hash)
    set_iri_prices(altered, price_set_hash)
    set_tamatsu_prices(altered, price_set_hash)
  end

  def set_and_save_prices
    self.oysters = @new_hash
    set_totals
    save
  end

  def update_prices(prices, altered)
    @new_hash = oysters.deep_dup
    prices.each do |prefecture, price_set_hash|
      case prefecture
      when 'hyogo'
        set_hyogo_prices(price_set_hash, altered)
      when 'okayama'
        set_okayama_prices(price_set_hash, altered)
      end
    end
    set_and_save_prices
  end

  # Fix errors in invoice subtotals
  def fix_invoice_subtotal(type, sup_num, volume, price, invoice)
    correct_invoice = (volume * price).to_s
    return unless volume.positive? && price.positive? && invoice != correct_invoice

    oysters[type][sup_num]['invoice'] = correct_invoice
  end

  def check_hyogo_invoice_subtotals
    set_types
    @types.each do |type|
      oysters[type].each do |sup_num, values_hash|
        volume = values_hash['volume'].to_f
        price = values_hash['price'].to_f
        invoice = values_hash['invoice'].to_f
        fix_invoice_subtotal(type, sup_num, volume, price, invoice)
      end
    end
  end

  def incorrect_invoice_calculation(values_hash)
    subtotal = values_hash['subtotal'].to_f
    price = values_hash['price'].to_f
    invoice = values_hash['invoice'].to_f
    correct_invoice = subtotal * price
    subtotal.positive? && price.positive? && (invoice.zero? || invoice != correct_invoice)
  end

  def check_hinase_invoice_subtotals(values_hash)
    return unless incorrect_invoice_calculation(values_hash)

    subtotal = values_hash['subtotal'].to_f
    price = values_hash['price'].to_f
    values_hash['invoice'] = subtotal * price
  end

  def recalculate_iri_subotals(values_hash)
    values_hash.each_with_object({ invoice: 0, volume: 0 }) do |(_, values), accu|
      next unless values.is_a?(Hash)

      accu[:invoice] += values[:volume].to_f * values[:price].to_f
      accu[:volume] += values[:volume].to_f
    end
  end

  def fix_iri_subtotals(values_hash, accumulator)
    values_hash['invoice'] = accumulator[:invoice].to_s
    values_hash['price'] = (accumulator[:invoice] / accumulator[:volume]).to_s
  end

  def check_iri_invoice_subtotals(values_hash)
    return unless incorrect_invoice_calculation(values_hash)

    accumulator = recalculate_iri_subotals(values_hash)
    fix_iri_subtotals(values_hash, accumulator)
  end

  def accumulate_tamatsu_figure(accu, values_hash, values)
    big_vol = values['大'].to_f
    sm_vol = values['小'].to_f
    accu[:invoice] += big_vol * values_hash['small_price'].to_f
    accu[:invoice] += sm_vol * values['price'].to_f
    accu[:big_vol] += big_vol
    accu[:small_vol] += sm_vol
  end

  def accumulate_tamatsu_figures(values_hash)
    values_hash.each_with_object(
      { invoice: 0, big_vol: 0, small_vol: 0 }
    ) do |(_, values), accu|
      next unless values.is_a?(Hash)

      accumulate_tamatsu_figure(accu, values_hash, values)
    end
  end

  def tamatsu_price_error(values_hash)
    sm_vol = @accumulator[:small_vol]
    big_vol = @accumulator[:big_vol]
    sm_price = values_hash['small_price'].to_f
    big_price = values_hash['price'].to_f
    sm_vol.zero? && big_vol.positive? && sm_price.positive? && big_price.zero?
  end

  def fix_tamatsu_price_error(values_hash)
    price = values_hash['small_price']
    values_hash['price'] = price
    invoice = 0
    values_hash.each do |_, values|
      next unless values.is_a?(Hash)

      values['price'] = price
      invoice += (values['大'].to_f * price.to_f)
    end
    values_hash['invoice'] = invoice.to_s
  end

  def accumulate_tamatsu_recalculation(accu, values, small_price)
    accu[:invoice] += (values['大'].to_f * values['price'].to_f)
    accu[:invoice] += (values['小'].to_f * small_price)
    accu[:subtotal] += (values['大'].to_f + values['小'].to_f)
  end

  def assign_tamatsu_reclaculation(recalculated, values_hash)
    values_hash['subtotal'] = recalculated[:subtotal]
    values_hash['invoice'] = recalculated[:invoice]
  end

  def recalculate_tamatsu_subtotals(values_hash)
    small_price = values_hash['small_price'].to_f
    recalculated = values_hash.each_with_object(
      { invoice: 0, subtotal: 0 }
    ) do |(_, values), accu|
      next unless values.is_a?(Hash)

      accumulate_tamatsu_recalculation(accu, values, small_price)
    end
    assign_tamatsu_reclaculation(recalculated, values_hash)
  end

  def tamatsu_subtotals_check(values_hash)
    @accumulator = accumulate_tamatsu_figures(values_hash)
    fix_tamatsu_price_error(values_hash) if tamatsu_price_error(values_hash)
    recalculate_tamatsu_subtotals(values_hash)
  end

  def check_tamtsu_invoice_subtotals(values_hash)
    return if values_hash['subtotal'].to_f.zero?

    tamatsu_subtotals_check(values_hash)
  end

  def check_okayama_invoice_subtotals
    oysters['okayama'].each do |locale_str, values_hash|
      case locale_str
      when 'hinase' then check_hinase_invoice_subtotals(values_hash)
      when 'iri' then check_iri_invoice_subtotals(values_hash)
      when 'tamatsu' then check_tamtsu_invoice_subtotals(values_hash)
      end
    end
  end

  def check_invoice_subtotals
    check_hyogo_invoice_subtotals
    check_okayama_invoice_subtotals
  end

  def update_and_fix_calculations
    check_invoice_subtotals
    set_totals
    year_to_date
    save
  end
end
