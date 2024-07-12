# frozen_string_literal: true

# Restaurant Order Packing Lists PDF Generator
class Invoice < Printable
  include SharedText
  include SupplierInvoice
  include UnionInvoice
  include SupplyIterators
  include InvoiceTableOne
  include InvoiceLayoutTwo
  include SupplierYearToDateTable

  # @param [Date] start_date
  # @param [Date] end_date
  # @param [String] location -> 'sakoshi' or 'aioi'
  # @param [String] format -> 'supplier' or 'union'
  # @param [String] password
  def initialize(start_date, end_date, location: 'sakoshi', format: 'union', layout: '2024', password: nil, invoice_date: nil)
    super(margin: [15, 15, 30, 15])
    set_supply_variables
    # Invoice dates are based on FullCalendar selections which include an extra day pass the selected range
    @date_range = start_date..(end_date - 1.day)
    @location = location
    @password = password
    @format = format
    @layout = layout.to_i
    @invoice_date = invoice_date
    set_password unless set_password.empty?
    send("generate_#{format}_invoice")
  end

  private

  def set_password
    encrypt_document(user_password: @password, owner_password: @password)
  end

  def supplies
    OysterSupply.with_date(@date_range).order(:date)
  end

  def suppliers
    case @location
    when 'sakoshi' then @sakoshi_suppliers
    when 'aioi' then @aioi_suppliers
    end
  end

  def supplier_numbers
    suppliers.pluck(:id).map(&:to_s)
  end

  def supply_dates
    supplies.pluck(:supply_date)
  end

  def print_supply_dates
    "#{@date_range.first} ~ #{@date_range.last}"
  end

  def accumulate_supplier_supply_date(supply, memo, values)
    values.each do |id, v|
      value = v['subtotal'].nil? ? v['0'].to_i : v['subtotal'].to_i
      next unless value.positive?

      memo[id.to_i] ||= Set.new
      memo[id.to_i] << supply.supply_date
    end
  end

  def supplier_supply_dates
    supplies.each_with_object({}) do |supply, memo|
      oysters = supply.oysters
      oysters.each do |time, type|
        next unless type.is_a?(Hash) && %w[am pm].include?(time)

        type.each { |_key, values| accumulate_supplier_supply_date(supply, memo, values) }
      end
    end
  end

  def company_info_cell
    { content: company_info, size: 8, align: :right }
  end

  def union_info_cell
    { content: unions_info, size: 8 }
  end

  def header
    [
      union_info_cell,
      { image: funabiki_logo, scale: 0.065, position: :center },
      company_info_cell
    ]
  end

  def document_title_row
    [{ content: document_title, colspan: 3, align: :center, valign: :center, height: 35,
       padding: 0 }]
  end

  def dates_title_row
    [{ content: print_supply_dates, colspan: 3, size: 8, padding: 4, align: :center }]
  end

  def header_rows
    [header, document_title_row, dates_title_row]
  end

  def header_table_config
    { position: :center, cell_style: { inline_format: true, border_width: 0 },
      width: bounds.width, column_widths: bounds.width / 3 }
  end

  def header_table
    table(header_rows, **header_table_config)
  end

  def spacer
    [{ content: '', colspan: 3, size: 8, padding: 2, align: :center }]
  end
end
