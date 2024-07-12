module Rakuten
  module Automation
    module SenderModification
      def new_order_sender
        # Used to set fix Sender Model name characters
        # modifies and simplifies item names
        # adds optional upsell items to order with new total price
        add_coupon_model(calculate_addons(new_sender_model))
      end

      def new_sender_model
        {
          'orderNumber' => @id,
          'PackageModelList' => sender_package_model_list
        }
      end

      def sender_package_model_list
        @packages.map do |pkg|
          postage_price = # For additional shipping
            pkg[:items_list].map do |item|
              item[:extra_delivery_cost]
            end.inject(0, :+)

          cod_tax_rate({
                         'basketId' => pkg[:basket_id],
                         'postageTaxRate' => 0.1,
                         'deliveryPrice' => pkg[:delivery_cost], # for COD
                         'postagePrice' => postage_price,
                         'SenderModel' => pkg[:sender_model],
                         'ItemModelList' => pkg[:item_model_list]
                       })
        end
      end

      def cod_tax_rate(package_model)
        package_model['deliveryTaxRate'] = 0.1 if cod_shipping
        package_model
      end

      def calculate_addons(sender_model)
        @knife_count, @tsukudani_count, @sauce_count = %W[\u7261\u8823\u30CA\u30A4\u30D5 \u4F43\u716E
                                                          Oyster38].map do |addon_string|
          count_addon(addon_string)
        end
        return sender_model unless [@knife_count, @tsukudani_count, @sauce_count].sum.positive?

        # 125 characters can fit in the wrapping model name
        # We can only add 2 wrapping models to an order, if there are 3 items we need to combine them
        sender_model['WrappingModel1'] = wrapping_model('牡蠣ナイフセット', @knife_count, 250, 0.1) if @knife_count.positive?
        if @tsukudani_count.positive?
          wrapping_model_num = @knife_count.positive? ? 'WrappingModel2' : 'WrappingModel1'
          sender_model[wrapping_model_num] = wrapping_model('サムライオイスター佃煮', @tsukudani_count, 650)
        end
        return sender_model unless @sauce_count.positive?

        if @knife_count.positive? && @tsukudani_count.positive?
          sender_model['WrappingModel2']['name'] += " Oyster38 オイスターソース#{"x #{@sauce_count}" if @sauce_count > 1}"
          sender_model['WrappingModel2']['price'] += (1500 * @sauce_count)
        else
          wrapping_model_num = @knife_count.positive? || @tsukudani_count.positive? ? 'WrappingModel2' : 'WrappingModel1'
          sender_model[wrapping_model_num] = wrapping_model('Oyster38 オイスターソース', @sauce_count, 1500)
        end
        sender_model
      end

      def count_addon(addon_string)
        selection_choices.map do |choice|
          choice&.include?(addon_string) && choice&.include?('希望する') ? 1 : 0
        end.compact.inject(0, :+)
      end

      def selection_choices
        # Example selection:
        # "牡蠣ナイフ・軍手片方セット:希望する(別途￥250)\n佃煮:希望する(別途￥650)\nOyster38:なし"
        @packages.map { |pkg| pkg[:items_list].map { |item| item[:selection]&.split("\n") } }.flatten
      end

      def wrapping_model(name, count, price, tax = 0.08)
        {
          'title' => 2,
          'name' => "#{name}#{"x #{count}" if count > 1}",
          'price' => price * count,
          'taxRate' => tax,
          'includeTaxFlag' => 1,
          'deleteWrappingFlag' => 0
        }
      end

      def add_coupon_model(sender_model)
        coupon_model = @order['CouponModelList']
        sender_model['CouponModelList'] = coupon_model if coupon_model

        sender_model
      end
    end
  end
end
