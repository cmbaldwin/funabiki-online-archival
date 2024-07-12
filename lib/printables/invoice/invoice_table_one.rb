# frozen_string_literal: true

class Invoice
  # Union Invoicetable crafting module - Mixin for Supplier Invoice PDF generator
  module InvoiceTableOne
    private

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
      daily_subtotals
      return unless @subtotals

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
      @subtotals.each_with_object([]) do |(date, types), memo|
        types.each_with_index do |(type, prices), type_index|
          prices.each_with_index do |(price, values), price_index|
            first_row = type_index.zero? && price_index.zero?
            memo << daily_subtotals_row(date, type, price, values, first_row)
          end
        end
        daily_totals_rows(memo, date, types)
      end
    end

    def daily_totals_rows(memo, date, types)
      memo << tax_row(date)
      types.map { |type, prices| memo << type_subtotal_row(type, prices) }
      range_totals(date)
    end

    def daily_subtotals_row(date, type, price, values, first_row)
      [first_row ? date : '', type_to_japanese(type), values['volume'], type_to_unit(type), yenify(price),
       yenify(values['invoice'].to_i), daily_total_cell(date, first_row)].compact
    end

    def daily_total_cell(date, first_row)
      return nil unless first_row

      rowspan = @subtotals[date].map { |_, prices| prices.size }.sum
      { content: yenify(daily_total(date)), rowspan:, valign: :bottom, font_style: :bold }
    end

    def tax_row(date)
      taxed_total = daily_total(date) * 0.08
      ['', '', '', '', '', align_right('消費税(8%)'), yenify(taxed_total)]
    end

    def daily_total(date)
      @subtotals[date].values.map { |prices| prices.values.map { |values| values['invoice'] }.sum }.sum
    end

    def type_subtotal_row(type, prices)
      volume_total = prices.values.map { |v| v['volume'] }.sum
      invoice_total = prices.values.map { |v| v['invoice'] }.sum
      ['', align_right("―#{type_to_japanese(type)}小計―"), align_right(volume_total), type_to_unit(type), '',
       yenify(invoice_total.to_i), '']
    end

    def align_right(content)
      { content: content.to_s, align: :right }
    end

    def range_total_rows
      @totals.map do |type, values|
        ['', align_right("―#{type_to_japanese(type)}合計―"), align_right(values['volume']), type_to_unit(type), '',
         yenify(values['invoice'].to_i), '']
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
