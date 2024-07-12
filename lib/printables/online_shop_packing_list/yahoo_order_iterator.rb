# frozen_string_literal: true

class OnlineShopPackingList
  # Yahoo @current_order Iterator - Mixin for Online @current_order Packing List PDF generator
  module YahooOrderIterator
    private

    def accumulate_yahoo_order(order, memo)
      @current_order = order
      @order_row = init_yahoo_item_cells
      @current_order.item_ids_counts.each do |item, count|
        @current_item = item
        accumulate_yahoo_item(count)
      end
      memo << @order_row
    end

    def accumulate_yahoo_item(count)
      new_cols = item_cells(count)
      new_cols.each_with_index { |cell, idx| @order_row[idx + 3] = cell unless cell.blank? }
    end

    def add_item_counts(count, row)
      row.insert(3, *item_cells(count))
    end

    def item_cells(count)
      Array.new(@headers.length, '').tap do |product_cols|
        EcProduct.with_reference_id(@current_item).each_with_index do |product, idx|
          product_cols[3] = "不明: #{@current_item}#{with_count(count)}" unless product
          next unless product

          add_item_count(product, count, idx, product_cols)
        end
      end
    end

    def with_count(count)
      " x#{count}" if count > 1
    end

    def init_yahoo_item_cells
      Array.new(9, '').tap do |row|
        row[0] = "#{@current_order_index}(ヤ)#{section_index}"
        sender_receiver_cells(row)
        arrival_time_cells(row)
        row[9] = @current_order.knife_count.zero? ? '' : @current_order.knife_count.to_s
        row[12] = yahoo_order_memo.squish
      end
    end

    def sender_receiver_cells(row)
      row[1] = @current_order.billing_name
      row[2] = @current_order.billing_name == @current_order.shipping_name ? '""' : @current_order.shipping_name
    end

    def arrival_time_cells(row)
      row[7] = yahoo_arrival_date
      row[8] = @current_order.arrival_time.gsub(':00', '時')
    end

    def yahoo_arrival_date
      arrival = @current_order.shipping_arrival_date
      arrival == @current_order.shipping_date + 1 ? '明日着' : arrival.strftime('%m月%d日')
    end

    def yahoo_order_memo
      <<~MEMO
        #{"佃煮x#{@current_order.tsukudani_count}" unless @current_order.tsukudani_count.zero?}
        #{"Oyster38x#{@current_order.sauce_count}" unless @current_order.sauce_count.zero?}
        #{@current_order.print_daibiki}
      MEMO
    end
  end
end
