# frozen_string_literal: true

class OnlineShopPackingList
  # Orders Table crafting module - Mixin for Online Order Packing List PDF generator
  module OrdersTable
    def orders_table(orders = all_orders, section: nil)
      orders = sort_orders(orders) if section
      table_data = iterate_orders(orders)
      table_data.unshift(orders_table_header)
      table(table_data, **orders_table_config) { |tbl| order_table_styles(tbl) }
    end

    private

    def sort_orders(orders)
      orders.sort_by do |order|
        quantity = ->(id) { EcProduct.with_reference_id(id).first&.quantity || 1 }
        products = order.item_ids_counts.map { |id, count| quantity.call(id) * count }.compact.sum
        [-products, order.class.name, order.order_time]
      end
    end

    def orders_table_header
      %w[# 注文者 送付先 お届け日 時間 ナイフ のし 領収書 備考].insert(3, *type_headers)
    end

    def type_headers
      @headers.values
    end

    def orders_table_config
      { header: true, cell_style: { border_width: 0.25, valign: :center },
        column_widths: { 0 => 33, 1 => 55, 2 => 55, 3 => 30, 4 => 30, 5 => 50, 12 => 90 }, width: bounds.width }
    end

    def iterate_orders(orders)
      orders.each_with_object([]) do |order, memo|
        @current_order_index ||= 0
        next if order.cancelled

        @current_order_index += 1
        delegate_order_accumulation(order, memo)
      end
    end

    def delegate_order_accumulation(order, memo)
      send "accumulate_#{order.class.name.underscore}", order, memo
    end

    def add_item_count(product, count, idx, memo)
      str = count_string(product, idx)
      str.prepend("#{count}x ") if count > 1
      memo[product.ec_product_type.section] += str
    end

    def minimum_height
      @table.cells.rows(1..-1).each do |r|
        r.height = 25 if r.height < 25
      end
    end

    def padding_and_name_font
      @table.cells.column(0).rows(1..-1).padding = 2
      @table.cells.columns(1..2).rows(1..-1).font = 'TakaoPMincho'
      @table.cells.columns(1..-1).rows(1..-1).padding = 4
    end

    def header_styling
      header_cells = @table.cells.columns(0..12).rows(0)
      header_cells.background_color = 'acacac'
      header_cells.size = 7
      header_cells.font_style = :bold
      # Arrival date cells, kinda a header, add lightness to draw attention
      @table.cells.columns(7).rows(1..-1).font_style = :light
    end

    def small_font_cells
      small_font_cells = @table.cells.columns([5, 6, 7, 8, 12]).rows(1..-1)
      small_font_cells.size = 7
    end

    def quantity_warning
      item_cells = @table.cells.columns(3..6).rows(1..-1)
      multi_cells = item_cells.filter do |cell|
        cell.content.to_s[/x/]
      end
      multi_cells.background_color = 'ffc48f'
    end

    def knife_receipt_noshi_warning
      item_cells = @table.cells.columns(9..11).rows(1..-6)
      check_cells = item_cells.filter do |cell|
        !cell.content.to_s.empty?
      end
      check_cells.background_color = 'ffc48f'
    end

    def cod_warning
      note_cells = @table.cells.columns(12).rows(1..-1)
      cash_cells = note_cells.filter do |cell|
        cell.content.to_s[/代引/]
      end
      cash_cells.background_color = 'ffc48f'
    end

    def date_warning
      date_cells = @table.cells.columns(7).rows(1..-1)
      not_tomorrow_cells = date_cells.filter do |cell|
        cell.content.to_s[/月/]
      end
      not_tomorrow_cells.background_color = 'ffc48f'
    end

    def order_table_styles(tbl)
      @table = tbl
      minimum_height
      padding_and_name_font
      header_styling
      small_font_cells
      quantity_warning
      knife_receipt_noshi_warning
      cod_warning
      date_warning
    end
  end
end
