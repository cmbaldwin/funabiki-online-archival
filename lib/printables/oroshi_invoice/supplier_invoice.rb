# frozen_string_literal: true

class OroshiInvoice
  # Supplier Invoice crafting module - Mixin for Supplier Invoice PDF generator
  module SupplierInvoice
    private

    def generate_supplier_invoice
      suppliers.each do |supplier|
        @current_supplier = supplier
        # Generate subtotals for each supplier, skip to the next supplier if it's empty
        next unless supply?

        start_new_page unless @current_supplier == suppliers.first
        supplier_invoice
        add_page_num
      end
      page_numbers
    end

    def supply?
      reset_iterators
      prepare_invoice_rows
      @subtotals.any?
    end

    def reset_iterators
      @totals = nil
      @subtotals = nil
      @range_total = nil
      @range_tax = nil
    end

    def supplier_invoice
      case @layout
      when 1
        supplier_invoice_layout_one
      when 2
        supplier_invoice_layout_two
      end
    end

    def supplier_invoice_layout_one
      layout_one_header
      move_down 20
      invoice_table_one
      move_down 20
      totals_table
    end

    def supplier_invoice_layout_two
      layout_two_header
      move_down 20
      invoice_table_two
      tax_warning_text
    end

    def add_page_num
      # Creates sections of page counts for each supplier by recording the last page number
      @page_counts ||= []
      @page_counts << (page_number)
    end

    def page_numbers
      @page_counts.each_with_index do |page, index|
        number_page(page, index)
      end
    end

    def number_page(page, index)
      page_range = (index.zero? ? 1 : @page_counts[index - 1] + 1)..page
      return if page_range.count < 2

      page_range.each_with_index do |page_number, num|
        go_to_page(page_number)
        bounding_box([bounds.right - 100, 0], width: 100, height: 20) do
          text "#{num + 1} / #{[*page_range].length}", size: 8, align: :right
        end
      end
    end
  end
end
