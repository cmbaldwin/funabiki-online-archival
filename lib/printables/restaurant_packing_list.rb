# frozen_string_literal: true

# Restaurant Order Packing Lists PDF Generator
class RestaurantPackingList < Printable
  def initialize(ship_date: Time.zone.today.to_date, blank: false)
    super()
    @ship_date = ship_date
    @orders = []
    @orders = InfomartOrder.with_date(ship_date).order(:order_time) unless blank
    generate_pdf
  end

  private

  def generate_pdf
    %i[raw frozen].each { |type| generate_order_table(type) }
  end

  def generate_order_table(type)
    @current_type = type
    header(type_str)
    table(send('table_data'), **table_options) { |table| style_table(table) }
    start_new_page if type == :raw
  end

  def header(type_str)
    text "#{@ship_date} #{type_str}の飲食店の発送表", style: :bold, size: 16
    move_down 15
    font_size 8
  end

  def type_str
    { raw: '生', frozen: '冷凍' }[@current_type]
  end

  def table_data
    table = [table_header]
    @orders.each_with_index do |order, order_index|
      next if order.counts.sum.zero?

      order.item_ids_counts.each_with_index do |(item, count), item_index|
        table << item_row(item_index, order_index, order, item, count)
      end
    end
    extra_empty_rows(table)
  end

  def item_row(item_index, order_index, order, item, count)
    contents = item_row_contents(item, count)
    return if contents.all?(&:blank?)

    [
      item_index.zero? ? order_index + 1 : '',
      order.destination,
      *contents,
      order.arrival_gapi,
      '午前　14-16',
      ' '
    ]
  end

  def item_row_contents(item, count)
    products = EcProduct.with_reference_id(item)
    Array.new(Setting.find_by(name: "restaurant_#{@current_type}_headers").settings.length, '').tap do |row|
      products.each do |product|
        product_type = product.ec_product_type
        cell_index = product_type.send("restaurant_#{@current_type}_section")
        row[cell_index] = "#{count * product.quantity}#{product_type.counter}" if cell_index
      end
    end
  end

  def table_header
    %w[# 飲食店 お届け日 時間 備考].insert(2, *headers)
  end

  def headers
    Setting.find_by(name: "restaurant_#{@current_type}_headers")&.settings&.values || []
  end

  def extra_empty_rows(data_table)
    # 19 is the approximate height of a row with two lines, subtract current size and buffer
    # 40 lines without items can fit, but with a little buffer 25 is best for blank lists
    extra_lines = items? ? (cursor / 22).to_i - data_table.size - 5 : 35
    columns = data_table.first.size
    return data_table unless extra_lines.positive?

    extra_lines.times { data_table << (['　'] * columns) }
    data_table.compact
  end

  def items?
    @orders.map { |order| order.item_array[@current_type].any? }.include?(true)
  end

  def style_table(table)
    table.cells.column(0).rows(1..-1).size = 7
    table.cells.column(-2).rows(1..-1).size = 6
    [table.columns(2..-1)].each { |r| r.style(align: :center) }

    header_cells = table.cells.columns(0..-1).rows(0)
    header_cells.cell_style = {
      background_color: 'acacac',
      size: 9,
      font_style: :bold
    }
  end

  def table_options
    {
      header: true,
      cell_style: {
        border_width: 0.25,
        valign: :center
      },
      column_widths:,
      width: bounds.width
    }
  end

  def column_widths
    { 0 => 20, 1 => 150, 2 => 50, -1 => 150, -2 => 50, -3 => 50 }
  end
end
