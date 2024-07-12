class SupplyCheck
  # Header and Footer module
  module SupplyTableStyles
    def table_styles(tbl)
      @tbl = tbl
      @all_supplier_rows_length = @supplier_organizations.map(&:suppliers).flatten.length * 2
      header_styles
      remove_borders
    end

    private

    def header_styles
      @tbl.row(3).size = 12
      @tbl.rows(3..4).font_style = :bold
    end

    def remove_borders
      # Second row and fourth to last row only top and bottom borders
      @tbl.row(3).borders = [:top, :bottom]
      @tbl.row(-4).borders = [:top, :bottom]
      # Second to last row only top border
      @tbl.row(-2).borders = [:top]
      # Last row no borders
      @tbl.row(-1).borders = []
    end
  end
end
