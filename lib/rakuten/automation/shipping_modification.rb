module Rakuten
  module Automation
    module ShippingModification
      def new_order_shipping
        # Used to set the Shipping Date for each Package Model
        {
          'orderNumber' => @id,
          'BasketidModelList' => basket_model_list
        }
      end

      def basket_model_list
        @packages.map.with_index do |pkg, _i|
          {
            'basketId' => pkg[:basket_id],
            'ShippingModelList' => [{
              'shippingDetailId' => pkg[:shipping_detail_ids]&.first,
              'deliveryCompany' => '1001',
              'deliveryCompanyName' => 'ヤマト運輸',
              'shippingDate' => shipping_date_wait ? nil : pkg[:shipping_date]
            }]
          }
        end
      end

      def modify_packages
        @impossible_delivery_time = false
        @packages = @order['PackageModelList'].map do |package|
          {
            sender_model: fix_sender_model(package),
            basket_id: package['basketId'],
            noshi: package['noshi'],
            delivery_cost: package['deliveryPrice'],
            shipping_date: calculate_shipping_date(package),
            shipping_detail_ids: package['ShippingModelList'].map { |ship| ship['shippingDetailId'] },
            item_model_list: item_model_list(package),
            items_list: items_list(package)
          }
        end
      end

      def items_list(package)
        prefecture = package['SenderModel']['prefecture']
        package['ItemModelList'].map do |item|
          id = sku_id(item)
          {
            id:,
            count: item['units'],
            selection: item['selectedChoice'],
            extra_delivery_cost: get_extra_cost(prefecture, id)
          }
        end
      end

      def sku_id(item)
        variant = item.dig('SkuModelList', 0, 'variantId') # in case older orders don't have skuModelList
        # normal-inventory is the default sku variant id when no variants are availiable
        variant = nil if variant == 'normal-inventory'
        variant || item['manageNumber']
      end

      def item_model_list(package)
        # Simple item names
        # [
        #   ["Oyster38 オイスターソース セット", "Oyster38"],
        #   ["サムライオイスター佃煮セット", "佃煮"]
        # ]
        choice_cleanup = [*get_setting('option_conversion_text')]
        package['ItemModelList'].map do |item|
          choice_cleanup.each { |arr| item['selectedChoice'].gsub!(arr[0], arr[1]) } if item['selectedChoice']
          item['itemName'] = simple_item_name(sku_id(item))
          item['taxRate'] = 0.08
          item
        end
      end

      def fix_sender_model(package)
        package['SenderModel'].transform_values do |str|
          next str if str.nil? || !str.is_a?(String)

          rakuten_prohibited_characters.reduce(str) { |char, (bad, good)| char.gsub(bad, good) }
        end
      end

      def rakuten_prohibited_characters
        # Occasionally the system will have allowed a user to register a name which is later prohibited by Rakuten
        # These are the two characters that have created error responses from the API so far (as of 2023-09-04)
        {
          '&' => ' and ',
          '・' => '.'
        }
      end

      def shipping_date_wait
        ship_wait_products = get_setting('rakuten_ship_wait_products') || []
        product_ship_wait = ship_wait_products.any? { |product| order_item_list.include?(product) }
        @order['SettlementModel']['settlementMethod'] == '銀行振込' || @order['SettlementModel']['settlementMethod'].include?('前払') || product_ship_wait
      end

      def order_item_list
        orders.last['PackageModelList'].map { |pkg| pkg['ItemModelList'] }.map do |items|
          items.map do |item|
            sku_id(item)
          end
        end.flatten
      end

      def cod_shipping
        @order['SettlementModel']['settlementMethod'] == '代金引換'
      end

      def isolated_island
        @order['isolatedIslandFlag'] == 1
      end
    end
  end
end
