# frozen_string_literal: true

# Supply Check PDF Generator
class SupplyCheck < Printable
  include HeaderAndFooter
  include SupplyTable
  include SupplyTableStyles

  def initialize(supply_date, subregion_ids, supply_reception_time_ids)
    super()
    @supply_date = Oroshi::SupplyDate.find_by(date: supply_date)
    @regions = subregion_ids
    @supply_reception_times = Oroshi::SupplyReceptionTime.where(id: supply_reception_time_ids)
    @first_page = true
    font_size 10
    generate_pdf
  end

  def spacer
    [{ content: '', colspan: 8, padding: 2 }]
  end

  private

  def generate_pdf
    @regions.each do |subregion_id|
      @supplier_organizations = ordered_supplier_organizations(subregion_id)
      @supply_reception_times.each do |receiving_time|
        @current_supply_reception_time = receiving_time
        next unless @supply_date.supplies.where(supply_reception_time: receiving_time).any?

        start_new_page unless @first_page
        table(table_constructor, **table_config) { |tbl| table_styles(tbl) }
        @first_page = false
      end
    end
  end

  def ordered_supplier_organizations(subregion_id)
    @supply_date.supplier_organizations
                .where(subregion_id: subregion_id).compact.uniq
                .sort_by { |so| -so.suppliers.count }
  end

  def table_constructor
    [
      *header,
      *supply_table,
      *footer
    ]
  end

  def table_config
    { position: :center, cell_style: { inline_format: true, border_width: 0.25 },
      width: bounds.width, column_widths: bounds.width / 8 }
  end
end
