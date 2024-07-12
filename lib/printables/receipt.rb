# frozen_string_literal: true

# Restaurant Order Packing Lists PDF Generator
class Receipt < Printable
  def initialize(options = { sales_date: '', order_id: '', purchaser: '', title: '', amount: '', expense_name: '',
                             oysis: '', tax_8_amount: '', tax_8_tax: '', tax_10_amount: '', tax_10_tax: '' })
    super(page_size: 'A5')
    @options = options
    @options = JSON.parse(options.gsub('=>', ':'), symbolize_names: true) if @options.is_a?(String)
    setup_options
    @date = @options[:sales_date]
    @date ||= Time.zone.now.strftime('%Y年%m月%d日')
    font 'TakaoPMincho'
    font_size 10
    generate_pdf
  end

  private

  def setup_options
    @rakuten = !@options[:oysis].to_i.zero?
    @title = @options[:title].nil? ? '様' : @options[:title]
    @expense = @options[:expense_name].blank? ? 'お品代として' : @options[:expense_name]
    @purchaser = @options[:purchaser]
    @amount = @options[:amount]
    @tax_8_amount = @options[:tax_8_amount]
    @tax_8_tax = @options[:tax_8_tax]
    @tax_10_amount = @options[:tax_10_amount]
    @tax_10_tax = @options[:tax_10_tax]
  end

  def generate_pdf
    move_down 10
    2.times do |i|
      table(receipt_table, **receipt_table_config) { |tbl| receipt_table_styles(tbl) }
      move_down 40 if i.zero?
    end
  end

  def receipt_table
    [header, date_and_purchaser, amount, purpose, tax_logo_info]
  end

  def receipt_table_config
    { cell_style: { inline_format: true, valign: :center, padding: 10 },
      width: bounds.width, column_widths: { 0..3 => (bounds.width / 3) } }
  end

  def header
    [{ content: '   領   収   証   ', colspan: 3, size: 17, align: :center }]
  end

  def date_and_purchaser
    [{ content: "<u>#{@purchaser}  #{@title}</u>",
       colspan: 2,
       size: 14,
       align: :center },
     { content: @date,
       colspan: 1,
       size: 10,
       align: :center }]
  end

  def amount
    [{ content: '★', size: 10, align: :center },
     { content: "<font size='18'>￥ #{@amount}</font>",
       size: 10,
       align: :center },
     { content: '★',
       size: 10,
       align: :center }]
  end

  def purpose
    [{ content: "但 #{@expense}<br>上  記  正  に  領  収  い  た  し  ま  し  た", size: 10,
       align: :center, valign: :bottom, colspan: 3 }]
  end

  def tax_logo_info
    [{ content: tax_table, padding: 0 },
     logo_cell,
     { content: info + invoice_number, size: 8 }]
  end

  def tax_table
    make_table(tax_table_cells, **tax_table_config) { |tbl| tax_style(tbl) }
  end

  def tax_table_cells
    [
      [{ content: '内訳', colspan: 2, align: :center, valign: :center, size: 10, height: 12 }],
      [{ content: '税率8%', rowspan: 2 }, "税抜金額  ¥#{@tax_8_amount}"],
      [{ content: "消費税額  ¥#{@tax_8_tax}" }],
      [{ content: '税率10%', rowspan: 2 }, "税抜金額  ¥#{@tax_10_amount}"],
      [{ content: "消費税額  ¥#{@tax_10_tax}" }]
    ]
  end

  def tax_table_config
    base_width = bounds.width / 3
    { cell_style: { inline_format: true, valign: :center, padding: 0 },
      width: base_width, column_widths: { 0..1 => base_width / 2 } }
  end

  def logo_cell
    logo = @rakuten ? oysis_logo : funabiki_logo
    { image: logo, scale: 0.05, position: :center,
      vposition: :center }
  end

  def info
    @rakuten ? rakuten_info : funabiki_info
  end

  def tax_style(tbl)
    tbl.cells.borders = %i[top left right bottom]
    tbl.cells.border_width = 0
    tbl.row(0).border_bottom_width = 0.5
    tbl.rows(1..-1).size = 7
    tbl.rows(1..-1).height = 10
    tbl.row(-3).border_bottom_width = 0.25
    tbl.row(-3).padding_bottom = 2
  end

  def receipt_table_styles(tbl)
    outside_borders(tbl)
    inside_borders(tbl)
    middle_section(tbl)
  end

  def outside_borders(tbl)
    tbl.cells.borders = %i[top left right bottom]
    tbl.cells.border_width = 0
    tbl.row(0).border_top_width = 0.25
    tbl.row(-1).border_bottom_width = 0.25
    tbl.column(0).border_left_width = 0.25
    tbl.column(-1).border_right_width = 0.25
  end

  def inside_borders(tbl)
    tbl.row(1).border_top_width = 0.25
    tbl.row(1).border_bottom_width = 0.25
    tbl.row(2).border_bottom_width = 0.25
    tbl.row(2).border_lines = %i[dotted solid dotted solid]
    tbl.row(1).border_lines = %i[dotted solid dotted solid]
  end

  def middle_section(tbl)
    tbl.row(2).background_color = 'EEEEEE'

    tbl.row(-2).column(0).border_bottom_width = 0.25
    tbl.row(-3).column(0).border_bottom_width = 0.25
    tbl.row(-2).column(0).border_lines = %i[dotted solid dotted solid]
    tbl.row(-3).column(0).border_lines = %i[dotted solid dotted solid]
  end
end
