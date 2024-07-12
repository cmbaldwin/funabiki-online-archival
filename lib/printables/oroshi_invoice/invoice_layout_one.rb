# frozen_string_literal: true

class OroshiInvoice
  # Union Invoicetable crafting module - Mixin for Supplier Invoice PDF generator
  module InvoiceLayoutOne
    private

    # Header
    def layout_one_header
      table(header_rows, **layout_one_header_config)
    end

    def header_rows
      [header, document_title_row, dates_title_row]
    end

    def header
      [
        organization_info_cell,
        { image: funabiki_logo, scale: 0.065, position: :center },
        company_info_cell
      ]
    end

    def organization_info_cell
      { content: organization_info, size: 8 }
    end

    def company_info_cell
      { content: company_info, size: 8, align: :right }
    end

    def document_title_row
      [{ content: document_title, colspan: 3, align: :center, valign: :center, height: 35,
         padding: 0 }]
    end

    def dates_title_row
      [{ content: print_supply_dates, colspan: 3, size: 8, padding: 4, align: :center }]
    end

    def layout_one_header_config
      { position: :center, cell_style: { inline_format: true, border_width: 0 },
        width: bounds.width, column_widths: bounds.width / 3 }
    end

    # Invoice Table
    def totals_table
      return unless @range_total

      start_new_page if (cursor - 50).negative? # generally around 40 height, but give it some padding
      (start_point = (bounds.width - 300) / 2) # center the table at a width of 300
      bounding_box([start_point, cursor], width: 300) do
        table(totals_table_data, **totals_table_config)
      end
    end

    def totals_table_data
      [
        %w[買上金額 消費税額 今回支払金額].map { |str| header_cell(str) },
        [yenify(@range_total.sum), yenify(@range_tax.sum), yenify(@range_total.sum + @range_tax.sum)]
      ]
    end

    def totals_table_config
      { width: 300,
        cell_style: { size: 12, padding: 4, height: 20, align: :center, border_width: 0.5 } }
    end

    def invoice_table_one
      table(invoice_table_data, **daily_subtotals_table_config) { |tbl| invoice_table_styles(tbl) }
    end

    def invoice_table_data
      [daily_subtotals_header, *daily_subtotals_rows, *range_total_rows]
    end

    def daily_subtotals_header
      %w[月日 商品名 数量 単位 単価 金額 総合計].map { |str| header_cell(str) }
    end

    def header_cell(content)
      { content:, font_style: :bold, size: 10, valign: :center, height: 20, padding: 4 }
    end

    def daily_subtotals_rows
      @subtotals.each_with_object([]) do |(date, supply_type_variations), memo|
        supply_type_variations.each_with_index do |(supply_type_variation, prices), type_index|
          prices.each_with_index do |(price, volume), price_index|
            first_row = type_index.zero? && price_index.zero?
            memo << daily_subtotals_row(date, supply_type_variation, price, volume, first_row)
          end
        end
        daily_totals_rows(memo, date, supply_type_variations)
      end
    end

    def daily_subtotals_row(date, supply_type_variation, price, volume, first_row)
      [first_row ? date : '', supply_type_variation.to_s, volume,
       supply_type_variation.units, yenify(price),
       yenify(price * volume), daily_total_cell(date, first_row)].compact
    end

    def daily_total(date)
      @subtotals[date].values.map { |prices| prices.map { |price, volume| price * volume }.sum }.sum
    end

    def daily_total_cell(date, first_row)
      return nil unless first_row

      rowspan = @subtotals[date].map { |_, prices| prices.size }.sum
      { content: yenify(daily_total(date)), rowspan:, valign: :bottom, font_style: :bold }
    end

    def daily_totals_rows(memo, date, supply_type_variations)
      memo << tax_row(date)
      supply_type_variations.map do |supply_type_variation, prices|
        memo << type_subtotal_row(supply_type_variation, prices)
      end
      range_totals(date)
    end

    def tax_row(date)
      taxed_total = daily_total(date) * 0.08
      ['', '', '', '', '', align_right('消費税(8%)'), yenify(taxed_total)]
    end

    def type_subtotal_row(supply_type_variation, prices)
      volume_total = prices.values.sum
      invoice_total = prices.map { |price, volume| price * volume }.sum
      ['', align_right("―#{supply_type_variation}小計―"), align_right(volume_total),
       supply_type_variation.units, '', yenify(invoice_total.to_i), '']
    end

    def align_right(content)
      { content: content.to_s, align: :right }
    end

    def range_totals(date)
      total = daily_total(date)
      @range_total ||= []
      @range_total << total
      @range_tax ||= []
      @range_tax << (total * 0.08)
    end

    def range_total_rows
      return unless @totals

      @totals.map do |supply_type_variation, values|
        ['', align_right("―#{supply_type_variation}合計―"), align_right(values['volume']),
         supply_type_variation.units, '', yenify(values['invoice'].to_i), '']
      end
    end

    def daily_subtotals_table_config
      { header: true, cell_style: { border_width: 0, size: 8, padding: 2 },
        width: bounds.width }
    end

    def invoice_table_styles(tbl)
      tbl.row([0]).border_width = [1, 0, 1, 0]
      day_lengths = @subtotals.values.map { |types| types.values.map(&:size).sum + types.size }
      day_final_rows = day_lengths.reduce([]) { |memo, length| memo << (memo.last.to_i + length + 1) }
      day_start_rows = day_final_rows.map { |row| row + 1 }
      tbl.row(day_final_rows).border_width = [0, 0, 0.5, 0]
      tbl.row(day_final_rows).border_lines = %i[solid solid dotted solid]
      tbl.row(day_start_rows).padding_top = 10
    end
  end
end
