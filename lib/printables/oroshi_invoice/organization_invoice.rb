# frozen_string_literal: true

class OroshiInvoice
  # Union Invoice crafting module - Mixin for Supplier Invoice PDF generator
  module OrganizationInvoice
    def generate_organization_invoice
      case @layout
      when 1
        invoice_layout_one
      when 2
        invoice_layout_two
      end
    end

    private

    def invoice_layout_one
      prepare_invoice_rows
      return text '支払いはない' unless @subtotals

      layout_one_header
      move_down 20
      invoice_table_one
      move_down 20
      totals_table
      number_pages '<page> / <total>',
                   { start_count_at: 0, page_filter: :all, at: [bounds.right - 100, 5], align: :right, size: 8 }
    end

    def invoice_layout_two
      prepare_invoice_rows
      return text '支払いはない' unless @subtotals

      layout_two_header
      move_down 5
      invoice_table_two
      move_down 20
      totals_table
      tax_warning_text
      number_pages '<page> / <total>',
                   { start_count_at: 0, page_filter: :all, at: [bounds.right - 100, 5], align: :right, size: 8 }
    end
  end
end
