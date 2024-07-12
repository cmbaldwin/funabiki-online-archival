# frozen_string_literal: true

# Oyster Supply Check PDF Generator
class OysterSupplyCheck < Printable
  include HeaderAndFooter
  include SupplyTable
  include SupplyTableStyles

  def initialize(supply, receiving_times: %w[am pm])
    super()
    @supply = supply
    @receiving_times = receiving_times
    set_supply_variables
    generate_pdf
  end

  def all_suppliers
    @sakoshi_suppliers + @aioi_suppliers
  end

  def spacer
    [{ content: '', colspan: 10, padding: 2 }]
  end

  private

  def table_constructor
    [
      *header,
      *supply_table,
      *footer
    ]
  end

  def table_config
    { position: :center, cell_style: { inline_format: true, border_width: 0 },
      width: bounds.width, column_widths: bounds.width / 10 }
  end

  def generate_pdf
    @receiving_times.each do |am_or_pm|
      @current_receiving_time = am_or_pm
      start_new_page if am_or_pm == 'pm' && @receiving_times.length == 2
      font_size 10
      table(table_constructor, **table_config) { |tbl| table_styles(tbl) }
    end
  end
end
