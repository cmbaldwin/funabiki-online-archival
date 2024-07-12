module Rakuten
  module Automation
    module MemoModification
      def new_order_memo
        # Changes Arrival Date if necessary
        # Updates delivery class based on item types
        # Marks an order as processed (substatus 15822)
        # Adds memos for easier identification

        generate_memo
        order_memo = {
          'orderNumber' => @id,
          'subStatusId' => 15_822, # Custom substatus for processed orders
          'deliveryClass' => set_delivery_class,
          'deliveryDate' => shipping_date_wait ? nil : @arrival_date.to_s,
          'memo' => generate_memo
        }
      end

      def set_delivery_class
        # Return frozen if any item in the list is frozen: true
        return 3 if frozen

        # Unless all items are 'nil' (常温), set to 2 (冷蔵)
        item_refrigeration.compact.empty? ? 1 : 2
      end

      def generate_memo
        [product_names, addons, noshi, delivery_time_error,
         delivery_days, isolated_island, additional_shipping_memo,
         frozen_memo, payment_memo, gift, remarks, date_remark,
         errors].join
      end

      def product_names
        @packages.map { |pkg| pkg[:items_list].map { |item| print_product_name(item) } }.flatten.join(' ')
      end

      def print_product_name(item)
        memo_product_name(item[:id]).to_s + multiple_quantity(item[:count])
      end

      def multiple_quantity(count)
        count.to_i > 1 ? " x#{count}" : ''
      end

      def addons
        [['ナイフ同梱', @knife_count],
         ['佃煮同梱', @tsukudani_count],
         ['ソース同梱', @sauce_count]].map { |arr| " #{arr[0]}" if arr[1].positive? }.compact.join
      end

      def noshi
        @packages.map { |pkg| pkg[:noshi] }.compact.empty? ? '' : ' のし'
      end

      def delivery_time_error
        @impossible_delivery_time ? ' 時間指定無理' : ''
      end

      def delivery_days
        days = @packages.map { |pkg| (@arrival_date - Date.parse(pkg[:shipping_date])).to_i }.max
        days > 1 ? " #{days}D" : ''
      end

      def isolated_island
        @order['isolatedIslandFlag'] == 1 ? ' 離島' : ''
      end

      def additional_shipping?
        @packages.map do |pkg|
          pkg[:items_list].map do |item|
            item[:extra_delivery_cost]
          end.inject(0, :+).positive?
        end.include?(true)
      end

      def additional_shipping_memo
        additional_shipping? ? ' 送料追加' : ''
      end

      def frozen_memo
        frozen ? ' 冷凍' : ''
      end

      def frozen
        item_refrigeration.include?(true)
      end

      def item_refrigeration
        @packages.map { |pkg| pkg[:items_list].map { |item| item_frozen?(item[:id]) } }.flatten.compact
      end

      def payment_memo
        payment_method = @order['SettlementModel']['settlementMethod']
        memo = if %W[\u4EE3\u91D1\u5F15\u63DB
                     \u9280\u884C\u632F\u8FBC].include?(payment_method)
                 " #{payment_method}"
               else
                 ''
               end
        memo += ' 前払' if payment_method.include?('前払')
        memo
      end

      def gift
        @order['giftCheckFlag'].zero? ? '' : ' ギフト'
      end

      def remarks
        remarks = @order['remarks'].delete("\n")[/(?<=\[メッセージ添付希望・他ご意見、ご要望がありましたらこちらまで:\]).*/]
        remarks.empty? ? '' : ' 備考あり'
      end

      def date_remark
        memo_date_memo = @order['remarks'].delete("\n")[/(?<=\[配送日時指定:\]).*(?=\[メッセージ)/].sub(/[0-9]{4}-(1[0-2]|0[1-9])-(3[01]|[12][0-9]|0[1-9])/, '').sub(/\(.\)(午前中)/, '').sub(/\(.\)/, '').sub(/[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}/, '').sub(
          '指定なし', ''
        )
        memo_date_memo.empty? ? '' : ' 時間指定備考あり'
      end

      def errors
        @errors.empty? ? '' : ' 自動処理エラー'
      end

      def shipping_date_wait
        order_items = @order['PackageModelList'].map do |pkg|
          pkg['ItemModelList'].map do |item|
            item['manageNumber']
          end
        end.flatten
        ship_wait_products = %w[barakaki_1k barakaki_2k barakaki_3k barakaki_5k]
        includes_anago = @packages.map do |pkg|
          pkg[:items_list].map do |item|
            item[:item_name]
          end
        end.flatten.join(' ').include?('穴子')
        product_wait = ship_wait_products.any? { |product| order_items.include?(product) } || includes_anago
        settlement_wait = @order['SettlementModel']['settlementMethod'] == '銀行振込' || @order['SettlementModel']['settlementMethod'].include?('前払')
        product_wait || settlement_wait
      end
    end
  end
end
