# frozen_string_literal: true

class Invoice
  # Union Invoicetable crafting module - Mixin for Supplier Invoice PDF generator
  module InvoiceLayoutTwo
    def standardized_header
      receiver, invoice_number = fetch_receiver_and_invoice_number

      data = [
        header_row,
        supply_dates_row,
        invoice_date_row,
        receiver_and_invoice_number_row(receiver, invoice_number),
        total_payment_row
      ]

      table(data, :width => bounds.width * 0.75, :position => :center) do
        self.cell_style = { borders: [] }
      end
    end

    private

    def fetch_receiver_and_invoice_number
      receiver = "〔#{@current_supplier&.supplier_number}〕 #{@current_supplier&.company_name}"
      receiver = print_union_name if @format == 'union'
      invoice_number = @current_supplier&.invoice_number || '-'
      invoice_number = print_union_invoice_number if @format == 'union'
      [receiver, invoice_number]
    end

    def header_row
      [{ :content => "支払明細書", :colspan => 2, font_style: :bold, size: 18, :align => :center, :padding_bottom => 10 }]
    end

    def supply_dates_row
      [{ :content => print_supply_dates, :colspan => 2, size: 12, :align => :center, :padding_bottom => 20 }]
    end

    def invoice_date_row
      [{ :content => @invoice_date&.strftime('%Y年%m月%d日') || supply_dates.last, size: 10, :colspan => 2, font: 'TakaoPMincho', :align => :right }]
    end

    def receiver_and_invoice_number_row(receiver, invoice_number)
      [{ :content => "<u>#{receiver}　#{receiver_greeting}</u>\n登録番号：#{invoice_number}",
         size: 10, font: 'TakaoPMincho', :align => :center, :padding_top => 20,
         :inline_format => true, :leading => 5 },
       { :content => funabiki_info_text,
         size: 10, font: 'TakaoPMincho', :align => :center, :valign => :bottom, :padding_top => 60,
         :padding_bottom => 50, :leading => 5, :inline_format => true }]
    end

    def receiver_greeting
      case @current_supplier&.location
      when '相生' then '様'
      else '御中'
      end
    end

    # Alternate to switch out with, just when I wrote it I didn't have time to test it out and confirm it works
    # def receiver_greeting(receiver)
    #   company_types = ['有限', '株', '組合', '合同会社', '株式会社']

    #   if company_types.any? { |type| receiver.include?(type) }
    #     '御中'
    #   else
    #     '様'
    #   end
    # end

    def total_payment_row
      [{ :content => "<u>支払金額合計： #{en_it(@invoice_subtotal + @tax_subtotal)}</u>", font_style: :bold, size: 12, :inline_format => true, colspan: 2 }]
    end

    def funabiki_info_text
      <<~INFO
        〒678-0232
        兵庫県赤穂市中広1576－11
        TEL (0791)43-6556 FAX (0791)43-8151
        メール info@funabiki.info
        株式会社船曳商店

        ※送付後一定期間内に連絡がない場合確認済とします
      INFO
    end

    def en_it(num, unit: '円', delimiter: ',')
      yenify(num, unit:, delimiter:)
    end

    def invoice_table_two
      data = [
        ["月日", { :content => "商品名", :colspan => 2 }, "数量", "単価", "金額"],
        *@invoice_rows,
        *tax_rows
      ]
      table(data, :width => bounds.width * 0.75, :position => :center) do
        self.cell_style = { border_width: 0.25, size: 9 }
        self.header = true
        row(0).style :align => :center
      end
    end

    def tax_rows
      [[{ content: "合計", colspan: 2, align: :center },
        { content: "仕入額", colspan: 2, align: :center },
        { content: "消費税額等", colspan: 2, align: :center }],
       [{ content: "8%対象", colspan: 2, align: :center },
        { content: en_it(@invoice_subtotal), colspan: 2, align: :center },
        { content: en_it(@tax_subtotal), colspan: 2, align: :center }],
       [{ content: "10%対象", colspan: 2, align: :center },
        { content: "0円", colspan: 2, align: :center },
        { content: "0円", colspan: 2, align: :center }]]
    end

    def fix_row_date(date)
      date.dup.gsub(/\d{4}年/, '')
    end

    def prepare_invoice_rows
      daily_subtotals if @format == 'union'
      return unless @subtotals

      @invoice_subtotal = 0
      @invoice_rows = @subtotals.flat_map do |date, subtotals|
        subtotals.flat_map do |type, prices|
          prices.map do |price, details|
            current_subtotal = price.to_f * details['volume'].to_f
            @invoice_subtotal += current_subtotal
            [fix_row_date(date),
             { content: "#{type_to_japanese(type)}  ※", colspan: 2 },
             { content: "#{details['volume']} #{type_to_unit(type)}", align: :center },
             { content: en_it(price.to_i, unit: ''), align: :center },
             { content: en_it(current_subtotal), align: :right }]
          end
        end
      end
      @tax_subtotal = @invoice_subtotal * 0.08
    end
  end
end
