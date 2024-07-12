# frozen_string_literal: true

# Restaurant Order Packing Lists PDF Generator
class OnlineShopPackingList < Printable
  include FunabikiOrderIterator
  include RakutenOrderIterator
  include YahooOrderIterator
  include OrdersTable

  def initialize(ship_date: Time.zone.today.to_date, blank: false, included: %w[rakuten yahoo funabiki],
                 sectioned: false)
    super()
    @ship_date = ship_date
    @included = included
    @sectioned = sectioned
    @headers = Setting.find_by(name: 'ec_headers').settings
    @headers ||= %w[500g セル セット その他]
    setup_orders
    determine_generator(blank)
  end

  def all_orders
    @rakuten_orders + @yahoo_orders + @funabiki_orders
  end

  def generate_pdf
    header
    item_count_table
    orders_table
  end

  def generate_sectioned
    sectioned_orders.each do |section, orders|
      @current_order_index = 0
      header(" 発送表 | #{section}")
      item_count_table(orders)
      orders_table(orders, section:)
      start_new_page unless section == sectioned_orders.keys.last
    end
  end

  def generate_blank
    header
  end

  private

  def setup_orders
    search = ->(shop) { "#{shop}_order".camelcase.constantize.send(:with_date, @ship_date).order(:order_time).reverse }
    %w[rakuten yahoo funabiki].each do |shop|
      orders = @included.include?(shop) ? search.call(shop) : []
      instance_variable_set("@#{shop}_orders", orders)
    end
  end

  def determine_generator(blank)
    if @sectioned
      generate_sectioned
    else
      blank ? generate_blank : generate_pdf
    end
  end

  def header(str = 'オンラインショップの発送表')
    text "#{@ship_date} #{str}", style: :bold, size: 16
    move_down 15
    font_size 8
  end

  def section_index
    "\n→(#{all_orders.index(@current_order) + 1})" if @sectioned
  end

  def knife_count
    all_orders.map(&:knife_count).sum
  end

  def accumulate_counts(item_id, count, memo)
    products = EcProduct.with_reference_id(item_id)
    products.each do |product|
      if product
        memo[product.ec_product_type] ||= 0
        memo[product.ec_product_type] += count * product.quantity.to_i
      else
        memo[item_id] ||= 0
        memo[item_id] += count
      end
    end
  end

  def item_counts(orders)
    orders.map(&:item_ids_counts).each_with_object({}) do |order, memo|
      order.each { |item_id, count| accumulate_counts(item_id, count, memo) }
    end
  end

  def count_table_config
    { cell_style: { inline_format: true, border_width: 0.25, valign: :center, align: :center, size: 10 },
      width: bounds.width }
  end

  def item_count_table(orders = all_orders)
    counts = item_counts(orders)
    count_headers = counts.map { |type, _| type.name }
    count_cells = counts.map { |type, count| "#{count}#{type.counter}" }
    counts_table = [count_headers.append('ナイフ'), count_cells.append("#{knife_count}本")]
    table(counts_table, **count_table_config) { |t| t.row(0).background_color = 'acacac' }
    move_down 10
  end

  def accumulate_item_to_section(item_id, order, memo)
    return if special_item?(order)

    product = EcProduct.with_reference_id(item_id).first
    if product
      memo[product.ec_product_type.name] ||= []
      memo[product.ec_product_type.name] << order
    else
      memo[item_id] ||= []
      memo[item_id] << order
    end
  end

  def special_item?(order)
    order.knife_count.positive? || order.sauce_count.positive? || order.tsukudani_count.positive?
  end

  def accumulate_special_sections(order, memo)
    if order.knife_count.positive? && !stacked?(order)
      memo['ナイフ'] ||= []
      memo['ナイフ'] << order
    elsif stacked?(order)
      memo['同梱'] ||= []
      memo['同梱'] << order
    end
  end

  def stacked?(order)
    order.sauce_count.positive? || order.tsukudani_count.positive?
  end

  def sectioned_orders
    all_orders.each_with_object({}) do |order, memo|
      next if order.cancelled

      order.item_ids_counts.to_h.each_key do |item_id|
        accumulate_item_to_section(item_id, order, memo)
        accumulate_special_sections(order, memo)
      end
    end
  end
end
