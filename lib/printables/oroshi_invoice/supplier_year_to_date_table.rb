# frozen_string_literal: true

class OroshiInvoice
  # Union Invoicetable crafting module - Mixin for Supplier Invoice PDF generator
  module SupplierYearToDateTable
    private

    def year_to_date
      return if supplies.empty?

      init_year_to_date_data
      move_down 10
      data = yearly_data
      offset = 130 + (26 * (data.size - 2))
      start_new_page if (cursor - offset).negative? # 26 for height of each row, 130 for base
      table(data, **year_to_date_table_config) { |tbl| year_to_date_styles(tbl) }
    end

    def year_to_date_table_config
      { position: :center, width: 545.28,
        cell_style: { inline_format: true, size: 7, align: :center, border_width: 0.25 } }
    end

    def year_to_date_styles(tbl)
      tbl.row(0).border_top_width = 1
      tbl.row(-1).border_bottom_width = 1
      tbl.column(0).border_left_width = 1
      tbl.column(-1).border_right_width = 1
    end

    def init_year_to_date_data
      @last_supply ||= supplies.last
      @ytd_data ||= @last_supply.year_to_date
      prior_season_nearby_date = @last_supply.date - 1.year
      prior_season_nearby_range = (prior_season_nearby_date - 5.days)..prior_season_nearby_date
      last_year_nearby_record = OysterSupply.where(date: prior_season_nearby_range).last
      @last_ytd_data ||= last_year_nearby_record&.year_to_date
    end

    def yearly_data_title
      date_range_str = @last_supply.year_to_date_range.to_s.gsub('..', ' ~ ')
      content = <<~TITLE
        <font size='10'><b>今シーズンの総合計算</b>
        （#{date_range_str}）</font>

        <font size='6'>[前シーズンの平均は下に（）に記載]</font>
      TITLE
      [{ content:, colspan: 4 }]
    end

    def yearly_data
      yearly = @ytd_data[@current_supplier.id.to_s]
      prior_yearly = @last_ytd_data ? @last_ytd_data[@current_supplier.id.to_s] : nil
        [
          yearly_data_title,
          ['', "計量合計\n(前年計量)", "平均単価\n(前年平均)", "合計金額\n(前年金額)"],
          *type_rows(yearly, prior_yearly)
        ]
    end

    def type_rows(yearly, prior_yearly)
      @types.map do |type|
        next unless yearly[type] && yearly[type][:volume].positive?

        type_row(yearly, prior_yearly, type, price_average(yearly, type), price_average(prior_yearly, type))
      end.compact
    end

    def price_average(yearly_data, type)
      return '0' unless yearly_data

      price_data = yearly_data.dig(type, :price)
      return '0' unless price_data

      price_average = (price_data.inject { |sum, el| sum + el }.to_f / price_data.size)
      price_average.nan? ? '0' : price_average
    end

    def type_row(yearly, prior_yearly, type, price_average, prior_average)
      [
        type_to_japanese(type),
        volume_cell_str(yearly, prior_yearly, type),
        average_price_cell_str(price_average, prior_average),
        invoice_cell_str(yearly, prior_yearly, type)
      ]
    end

    def volume_cell_str(yearly, prior_yearly, type)
      "#{yenify(yearly[type][:volume])} #{type_to_unit(type)}\n(#{prior_yearly ? yenify(prior_yearly.dig(type, :volume)) : '0'} #{type_to_unit(type)})"
    end

    def average_price_cell_str(price_average, prior_average)
      "¥#{yenify(price_average.to_f.round(0))}\n(¥#{yenify(prior_average.to_f.round(0))})"
    end

    def invoice_cell_str(yearly, prior_yearly, type)
      "¥#{yenify(yearly[type][:invoice])}\n(¥#{prior_yearly ? yenify(prior_yearly.dig(type, :invoice)) : '0'})"
    end
  end
end
