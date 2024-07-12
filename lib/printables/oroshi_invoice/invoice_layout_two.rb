# frozen_string_literal: true

class OroshiInvoice
  # Union Invoicetable crafting module - Mixin for Supplier Invoice PDF generator
  module InvoiceLayoutTwo
    private

    # Header
    def layout_two_header
      table([
              header_row,
              supply_dates_row,
              invoice_date_row,
              receiver_and_invoice_number_row,
              total_payment_row
            ], width: bounds.width * 0.75, position: :center) do
        self.cell_style = { borders: [] }
      end
    end

    def header_row
      [{ content: "支払明細書", colspan: 2, font_style: :bold, size: 18, align: :center, padding_bottom: 10 }]
    end

    def supply_dates_row
      [{ content: print_supply_dates, colspan: 2, size: 12, align: :center, padding_bottom: 20 }]
    end

    def invoice_date_row
      date = l(@invoice_date || supply_dates.last.date, format: :long)
      [{ content: date, size: 10, colspan: 2, font: 'TakaoPMincho', align: :right }]
    end

    def receiver_and_invoice_number_row
      [{ content: receiver_info_text,
         size: 10, font: 'TakaoPMincho', align: :center, padding_top: 20,
         inline_format: true, leading: 5 },
       { content: funabiki_info_text,
         size: 10, font: 'TakaoPMincho', align: :center, valign: :bottom, padding_top: 60,
         padding_bottom: 50, leading: 5, inline_format: true }]
    end

    def receiver_info_text
      formatted_name = "<u>#{current_receiver.invoice_name}　#{current_receiver.honorific_title}</u>"
      "#{formatted_name}\n登録番号：#{current_receiver.invoice_number}"
    end

    def current_receiver
      @current_supplier || @supplier_organization
    end

    def total_payment_row
      [{ content: "<u>支払金額合計： #{en_it(@invoice_subtotal + @tax_subtotal)}</u>",
         font_style: :bold, size: 12, inline_format: true, colspan: 2 }]
    end

    # Body
    def invoice_table_two
      table([
              ["月日", { content: "商品名", colspan: 2 }, "数量", "単価", "金額"],
              *@invoice_rows,
              *tax_rows
            ], width: bounds.width) do # * 0.75, position: :center
        self.cell_style = { border_width: 0.25, size: 9 }
        self.header = true
        row(0).style align: :center
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
  end
end
