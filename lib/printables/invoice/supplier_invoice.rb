# frozen_string_literal: true

class Invoice
  # Supplier Invoice crafting module - Mixin for Supplier Invoice PDF generator
  module SupplierInvoice
    private

    def generate_supplier_invoice
      @first_page = true
      suppliers.each do |supplier|
        @current_supplier = supplier
        # Generate subtotals for each supplier, skip to the next supplier if it's empty
        next unless supply?

        start_new_page unless @first_page
        @first_page = false
        supplier_invoice
        add_page_num
      end
      page_numbers if @page_counts
    end

    def supply?
      reset_iterators
      daily_subtotals
      @subtotals
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
        supplier_invoice_layout_one # from InvoiceTableOne from 2018
      when 2
        supplier_invoice_layout_two # from InvoiceLayoutTwo from 2023
      end
    end

    def supplier_invoice_layout_one
      header_table
      move_down 5
      # manually call the table because we've already done the daily_subtotals calculation iteration in 'supply?'
      table(invoice_table_data, **daily_subtotals_table_config) { |tbl| invoice_table_styles(tbl) }
      move_down 20
      totals_table
      year_to_date
    end

    def supplier_invoice_layout_two
      prepare_invoice_rows
      standardized_header
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
      @page_counts[-1] = @page_counts[-1]
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
