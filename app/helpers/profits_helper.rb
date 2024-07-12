module ProfitsHelper
  def print_supply_date_links
    return '' if @profit.associated_supplies.compact.empty?

    @profit.associated_supplies.map do |supply|
      link_to to_nengapi(supply.date),
              supply,
              class: 'small d-inline',
              data: { turbo_frame: 'app' }
    end.join(', ').html_safe
  end

  def shared_profits_links
    @profit.shared_profits.map do |profit|
      link_to to_nengapi(profit.date) + print_ampm(profit),
              profit,
              class: 'small d-inline text-warning',
              enddata: { turbo_frame: 'app' }
    end.join('と').html_safe
  end

  def print_ampm(profit)
    return '' if profit.alone?

    # am == true, pm == false
    profit&.check_ampm ? ' 午前' : ' 午後'
  end

  def types_hashes
    @products = Product.all
    @markets = Market.all
    # set up types hash (number as key, type as value)
    @types_hash = { '1' => 'トレイ', '2' => 'チューブ', '3' => '水切り', '4' => '殻付き', '5' => '冷凍', '6' => '単品' }
  end

  def type_to_text(type_str)
    { '1' => 'トレイ', '2' => 'チューブ', '3' => '水切り', '4' => '殻付き', '5' => '冷凍', '6' => '単品' }[(type_str)]
  end

  def get_product_grams(product_id)
    @product_data[product_id]['grams'].to_f
  end

  def get_product_name(product_id)
    @product_data[product_id]['namae']
  end

  def get_product_cost(product_id)
    @product_data[product_id]['cost'].to_f
  end

  def get_product_box_count(product_id)
    @product_data[product_id]['multiplier'].to_f
  end

  def get_product_product_per_box(product_id)
    @product_data[product_id]['count'].to_f
  end

  def get_product_average_price(product_id)
    @product_data[product_id]['average_price'].to_f
  end

  def strange_price_check(product_id, unit_price)
    if (unit_price > (get_product_average_price(product_id) * 1.51)) ||
       (unit_price < (get_product_average_price(product_id) * 0.49))
      'text-danger'
    else
      'text-info'
    end
  end

  def adjust_totals(profits)
    adjust_totals = 0
    profits.each do |profit|
      adjust_totals += profit.totals[:profits]
    end
    adjust_totals
  end

  def active(idx)
    'active ' if idx.zero?
  end

  def profit_nav_font_color(color)
    ['#ffffff', '#FFFFFF', '#e3fffc', '#f0f0f0', '#efeff2'].include?(color) ? 'light-pill' : 'dark-pill'
  end

  def add_html_input_value(input_html, value)
    input_html[:value] = value.to_i if value&.positive?
    input_html
  end

  def figure_search(type, product_by_market, market, search_sym)
    @profit.figures&.dig(type.to_i, product_by_market.id, market.id, search_sym)
  end

  def unit_cost_html(type, product_by_market, market)
    input_html = {
      type: 'number',
      step: '1',
      min: '0',
      id: "#{product_by_market.id}-#{market.id}-price",
      data: {
        profits__edit_market_target: 'input',
        input_type: 'unit_price',
        paired_input: "#{product_by_market.id}-#{market.id}-count",
        average_price: product_by_market.average_price.to_i.to_s
      }
    }
    add_html_input_value(input_html, figure_search(type, product_by_market, market, :unit_price))
  end

  def unit_cost(figures_form, type, product_by_market, market)
    figures_form.input :unit_price,
                       placeholder: '単価',
                       type: 'number',
                       label: false,
                       input_html: unit_cost_html(type, product_by_market, market)
  end

  def order_count_html(type, product_by_market, market)
    input_html = {
      type: 'number',
      step: '1',
      min: '0',
      id: "#{product_by_market.id}-#{market.id}-count",
      data: {
        profits__edit_market_target: 'input',
        input_type: 'order_count',
        paired_input: "#{product_by_market.id}-#{market.id}-price"
      }
    }
    add_html_input_value(input_html, figure_search(type, product_by_market, market, :order_count))
  end

  def order_count(figures_form, type, product_by_market, market)
    figures_form.input :order_count,
                       placeholder: '売り数',
                       type: 'number',
                       label: false,
                       input_html: order_count_html(type, product_by_market, market)
  end

  def fetch_market_setting(type, product_by_market, market, setting)
    # Check that there is not already options for this product (this would only occur if the count or price is filled out)
    if @profit.figures.dig(type.to_i, product_by_market.id, market.id, setting)
      combined = !@profit.figures[type.to_i][product_by_market.id][market.id][setting].zero?
    # If there isn't already a figure for this and this isn't a new entry, check the last profit entry for values
    elsif @previous && @two_previous
      if !@previous.figures.dig(type.to_i, product_by_market.id, market.id, setting).nil?
          combined = !@previous.figures[type.to_i][product_by_market.id][market.id][setting].zero?
      elsif !@two_previous.figures.dig(type.to_i, product_by_market.id, market.id, setting).nil?
          combined = !@two_previous.figures[type.to_i][product_by_market.id][market.id][setting].zero?
      end
        combined ||= false
    end
  end
end
