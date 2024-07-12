# frozen_string_literal: true

class OnlineShopPackingList
  # Yahoo @current_order Iterator - Mixin for Online @current_order Packing List PDF generator
  module FunabikiOrderIterator
    private

    def accumulate_funabiki_order(order, memo)
      @current_order = order
      @order_row = init_funabiki_item_cells
      @current_order.item_ids_counts(exclude_knife: true).each do |item, count|
        @current_item = item
        accumulate_funabiki_item(count)
      end
      memo << @order_row
    end

    def accumulate_funabiki_item(count)
      new_cols = item_cells(count) # to YahooOrderIterator#item_cells
      new_cols.each_with_index { |cell, idx| @order_row[idx + 3] = cell unless cell.blank? }
    end

    def init_funabiki_item_cells
      Array.new(9, '').tap do |row|
        row[0] = "#{@current_order_index}(F)#{section_index}"
        sender_receiver_cells(row) # to YahooOrderIterator#sender_receiver_cells
        arrival_time_cells(row) # to YahooOrderIterator#arrival_time_cells
        row[9] = @current_order.knife_count.zero? ? '' : @current_order.knife_count.to_s
        row[12] = @current_order.memo.squish
      end
    end
  end
end
