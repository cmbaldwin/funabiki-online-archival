class OysterSupplyCheck
  # Header and Footer module
  module SupplyTableStyles
    def table_styles(tbl)
      @tbl = tbl
      @all_supplier_rows_length = (@sakoshi_suppliers.length + @aioi_suppliers.length) * 2
      header_styles
      outside_borders
      right_confirmation_border
      locality_divider

      @tbl.cells.rows(5..@all_supplier_rows_length + 5).columns(0..8).style do |c|
        c.border_width = 0.25 if (c.row % 2).zero? && (c.column != 1) && (c.column != 2)
        c.border_right_width = 0.25 && c.border_bottom_width = 0.25 if !(c.row % 2).zero? && (c.column == 1)
        c.border_left_width = 0.25 if (c.row % 2).zero? && (c.column == 2)
        c.border_bottom_width = 0.25 if !(c.row % 2).zero? && (c.column == 2)
        c.border_right_width = 0.25 if c.column == 8
        @tbl.rows(c.row).columns(2..8).background_color = 'cfcfcf' if c.background_color == 'cfcfcf'
      end
    end

    private

    def header_styles
      @tbl.row(3).size = 12
      @tbl.rows(3..4).font_style = :bold
    end

    def right_confirmation_border
      @tbl.rows(6..(@all_supplier_rows_length + 5)).columns(-1).border_right_width = 0.25
      @tbl.row(@all_supplier_rows_length + 5).border_bottom_width = 0.25
    end

    def outside_borders
      @tbl.rows(0..2).columns(0..-1).border_width = 0.25
      @tbl.row(-3).border_width = 0.25
      @tbl.rows(4..5).border_width = 0.25
    end

    def locality_divider
      @tbl.row(5 + (@sakoshi_suppliers.length * 2)).column(-1).border_bottom_width = 0.25
    end
  end
end
