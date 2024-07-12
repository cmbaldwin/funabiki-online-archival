# frozen_string_literal: true

class OnlineShopPackingList
  # Rakuten Order Iterator - Mixin for Online Order Packing List PDF generator
  module RakutenOrderIterator
    private

    def accumulate_rakuten_order(order, memo)
      @current_order = order
      @current_order.packages.each_with_index do |pkg, index|
        @current_pkg = pkg
        @pkg_index = index
        next unless @current_order.ship_date(@current_pkg) == @ship_date

        memo << accumulate_row
      end
    end

    def rakuten_memo
      <<~MEMO
        #{@current_order.remark_message unless @current_order.remark_message.empty?}
        #{"代引：￥ #{@current_order.charged}" if @current_order.settlement_method == '代金引換'}
        #{"佃煮x#{@current_order.tsukudani_set}" unless @current_order.tsukudani_set.zero?}
        #{"Oyster38x#{@current_order.sauce_set}" unless @current_order.sauce_set.zero?}
      MEMO
    end

    def print_cell(str)
      @current_order.packages.first == @current_pkg ? str.to_s : '↑'
    end

    def name_cells
      recipient = @current_order.print_recipient_name(@current_pkg)
      [
        print_cell("#{@current_order_index}(楽)#{section_index}"), # number row
        print_cell(@current_order.print_sender_name), # sender
        (@current_order.sender_recipient(@current_pkg) ? '""' : recipient) # recipent
      ]
    end

    def count_string(product, idx)
      "#{' + ' if idx.positive?} #{product.quantity}#{product.ec_product_type.counter}"
    end

    def count_cells
      Array.new(@headers.length, '').tap do |memo|
        @current_order.items(@current_pkg).each do |item|
          id = sku_id(item)
          count = item['units']
          iterate_count_cell_items(memo, id, count)
        end
      end
    end

    def sku_id(item)
      variant = item.dig("SkuModelList", 0, "variantId") # in case older orders don't have skuModelList
      variant = nil if variant == 'normal-inventory' # normal-inventory is the default sku variant id when no variants are availiable
      variant || item["manageNumber"]
    end

    def iterate_count_cell_items(memo, id, count)
      EcProduct.with_reference_id(id).each_with_index do |product, idx|
        memo[3] = "不明: #{id_count}" unless product
        next unless product

        add_item_count(product, count, idx, memo)
      end
    end

    def rakuten_arrival_date
      arrival = @current_order.arrival_date
      arrival == @current_order.ship_date(@current_pkg) + 1 ? '明日着' : arrival.strftime('%m月%d日')
    end

    def arrival_cells
      [
        print_cell(rakuten_arrival_date), # arrival date
        print_cell(@current_order.print_arrival_time) # arrival time
      ]
    end

    def extras_cells
      knife = @current_order.knife_count
      [
        print_cell((knife unless knife.zero?)), # knife count
        print_cell(('✓' unless @current_order.noshi.empty?)) # noshi
      ]
    end

    def memo_cells
      [
        print_cell(@current_order.receipt.empty? ? '' : @current_order.receipt), # reciept
        print_cell(rakuten_memo.squish) # memo etc
      ]
    end

    def accumulate_row
      [
        *name_cells,
        *count_cells,
        *arrival_cells,
        *extras_cells,
        *memo_cells
      ]
    end
  end
end
