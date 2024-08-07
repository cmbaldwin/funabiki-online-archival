# In your FactoryBot definitions file (e.g., test/factories/funabiki_orders.rb)

FactoryBot.define do
  factory :funabiki_order do
    order_id { FFaker::Number.unique.number(digits: 9).to_s }
    order_time { FFaker::Time.between(2.days.ago, Time.current) }
    ship_date { FFaker::Date.forward(0) }
    arrival_date { FFaker::Date.forward(1) }
    ship_status { "pending" }
    data do
      {
        id: id,
        number: order_id,
        item_total: "3300.0",
        total: "3300.0",
        ship_total: "0.0",
        state: "complete",
        adjustment_total: "0.0",
        user_id: nil,
        created_at: order_time.iso8601,
        updated_at: FFaker::Time.between(order_time, Time.current).iso8601,
        completed_at: FFaker::Time.between(order_time, Time.current).iso8601,
        payment_total: "0.0",
        shipment_state: "pending",
        payment_state: "balance_due",
        email: 'user@test.com',
        special_instructions: "",
        channel: "spree",
        included_tax_total: "0.0",
        additional_tax_total: "0.0",
        display_included_tax_total: "0円",
        display_additional_tax_total: "0円",
        tax_total: "0.0",
        currency: "JPY",
        covered_by_store_credit: false,
        display_total_applicable_store_credit: "0円",
        order_total_after_store_credit: "3300.0",
        display_order_total_after_store_credit: "3,300円",
        total_applicable_store_credit: 0,
        display_total_available_store_credit: "0円",
        display_store_credit_remaining_after_capture: "0円",
        canceler_id: nil,
        arrival_date: arrival_date.iso8601,
        arrival_time: "時間指定なし",
        shipping_date: ship_date.to_s,
        noshi: false,
        noshi_name: "",
        noshi_occasion: "",
        receipt: "no_receipt",
        display_item_total: "3,300円",
        total_quantity: 1,
        display_total: "3,300円",
        display_ship_total: "0円",
        display_tax_total: "0円",
        token: SecureRandom.uuid,
        checkout_steps: ["address", "delivery", "payment", "confirm", "complete"],
        payment_methods: [
          { "id" => 38, "name" => "ストライプ・カード決済（Stripe Credit Card Payment）", "partial_name" => "stripe", "method_type" => "stripe" },
          { "id" => 40, "name" => "代金引換決済 ーヤマト運輸（Yamato Kuroneko COD Service）", "partial_name" => "daibiki", "method_type" => "daibiki" },
          { "id" => 39, "name" => "銀行振り込み（Japanese Bank Transfer）", "partial_name" => "furikomi", "method_type" => "furikomi" }
        ],
        bill_address: {
          "id" => FFaker::Number.unique.number(digits: 4),
          "name" => FFaker::NameJA.last_name + FFaker::NameJA.first_name,
          "address1" => "",
          "address2" => "#{rand(1..30)}-#{rand(1..30)}",
          "city" => "",
          "zipcode" => "",
          "phone" => FFaker::PhoneNumberJA.phone_number,
          "company" => nil,
          "alternative_phone" => nil,
          "country_id" => 114,
          "country_iso" => "JP",
          "state_id" => 1403,
          "state_name" => nil,
          "state_text" => "14",
          "country" => { "id" => 114, "iso_name" => "JAPAN", "iso" => "JP", "iso3" => "JPN", "name" => "Japan", "numcode" => 392 },
          "state" => { "id" => 1403, "name" => "神奈川県", "abbr" => "14", "country_id" => 114 }
        },
        ship_address: {
          "id" => FFaker::Number.unique.number(digits: 4),
          "name" => FFaker::NameJA.last_name + FFaker::NameJA.first_name,
          "address1" => "",
          "address2" => "",
          "city" => "",
          "zipcode" => "",
          "phone" => FFaker::PhoneNumberJA.phone_number,
          "company" => nil,
          "alternative_phone" => nil,
          "country_id" => 114,
          "country_iso" => "JP",
          "state_id" => 1403,
          "state_name" => nil,
          "state_text" => "14",
          "country" => { "id" => 114, "iso_name" => "JAPAN", "iso" => "JP", "iso3" => "JPN", "name" => "Japan", "numcode" => 392 },
          "state" => { "id" => 1403, "name" => "神奈川県", "abbr" => "14", "country_id" => 114 }
        },
        line_items:
          [{ "id" => 2295,
             "quantity" => 1,
             "price" => "3300.0",
             "variant_id" => 3,
             "single_display_amount" => "3,300円",
             "display_amount" => "3,300円",
             "total" => "3300.0",
             "variant" =>
            { "id" => 3,
              "name" => "【年内28日お届けまで】Samurai Oyster (サムライオイスター) 坂越かき 生牡蠣 むき身 500g 【送料込み】【税込】",
              "sku" => "",
              "weight" => "550.0",
              "height" => "31.3",
              "width" => "24.3",
              "depth" => "12.0",
              "is_master" => false,
              "slug" => "mukimi",
              "description" =>
              { "id" => 99,
                "name" => "description",
                "body" =>
                "<div>熱を加えても縮みにくく、<br>コクと甘みのある最高級のかきです。<br>酢牡蠣やフライ、お鍋などでお召し上がり下さい。<br>(1pack: 3～4名様)<br><br>◆賞味期限：発送日を含め５日(冷蔵庫保管)<br><br> </div><div>【年末年始休業日のお知らせ】<br><br>いつも当店をご利用いただきありがとうございます。<br>誠に勝手ながら、12月30日(土)～1月4日(水)の期間は休業期間とさせていただきます。<br> ★<strong>年内お届け最終は１２／２８(金)です</strong>★<br>休業期間後は、1月9日(火)お届けより、ご注文をお受け致します。<br>休業期間中は、お客様にご迷惑をおかけしますが、ご理解賜りますようお願い申し上げます。</div><div><br></div><div><br><br></div>",
                "record_type" => "Spree::Product",
                "record_id" => 1,
                "created_at" => "2022-08-22T10:08:26.884+09:00",
                "updated_at" => "2023-12-13T18:41:58.648+09:00",
                "locale" => nil },
              "track_inventory" => true,
              "cost_price" => "3300.0",
              "price" => "3300.0",
              "display_price" => "3,300円",
              "options_text" => "パック数: 1パック",
              "in_stock" => true,
              "is_backorderable" => false,
              "total_on_hand" => 9974,
              "is_destroyed" => false,
              "option_values" => [{ "id" => 1, "name" => "1", "presentation" => "1パック", "option_type_name" => "むき身牡蠣 パック数", "option_type_id" => 1, "option_type_presentation" => "パック数" }],
              "images" =>
              [{ "id" => 6,
                 "position" => 5,
                 "attachment_content_type" => nil,
                 "attachment_file_name" => nil,
                 "type" => "Spree::Image",
                 "attachment_updated_at" => nil,
                 "attachment_width" => 600,
                 "attachment_height" => 600,
                 "alt" => "サムライオイスター 生牡蠣 むき身 500g x 1",
                 "viewable_type" => "Spree::Variant",
                 "viewable_id" => 3,
                 }],
              "product_id" => 1 },
             "adjustments" =>
            [{ "id" => 2829,
               "source_type" => "Spree::TaxRate",
               "source_id" => 1,
               "adjustable_type" => "Spree::LineItem",
               "adjustable_id" => 2295,
               "amount" => "0.0",
               "label" => "日本（税込） 0.000% (価格に含まれています)",
               "promotion_code_id" => nil,
               "finalized" => true,
               "eligible" => true,
               "created_at" => "2023-12-13T23:22:22.365+09:00",
               "updated_at" => "2023-12-13T23:25:30.761+09:00",
               "display_amount" => "0円" }] }],
        payments:
          [{ "id" => 1344,
             "source_type" => nil,
             "source_id" => nil,
             "amount" => "3300.0",
             "display_amount" => "3,300円",
             "payment_method_id" => 39,
             "state" => "checkout",
             "avs_response" => nil,
             "created_at" => "2023-12-13T23:24:46.259+09:00",
             "updated_at" => "2023-12-13T23:24:46.259+09:00",
             "payment_method" => { "id" => 39, "name" => "銀行振り込み（Japanese Bank Transfer）" },
             "source" => nil }],
        shipments:
          [{ "id" => 1595,
             "tracking" => nil,
             "tracking_url" => nil,
             "number" => "H57214771504",
             "cost" => "0.0",
             "shipped_at" => nil,
             "state" => "pending",
             "order_id" => "R753746146",
             "stock_location_name" => "船曳商店",
             "shipping_rates" => [{ "id" => 1594, "name" => "ヤマト運輸 - 宅急便", "cost" => "0.0", "selected" => true, "shipping_method_id" => 1, "shipping_method_code" => "", "display_cost" => "0円" }],
             "selected_shipping_rate" => { "id" => 1594, "name" => "ヤマト運輸 - 宅急便", "cost" => "0.0", "selected" => true, "shipping_method_id" => 1, "shipping_method_code" => "", "display_cost" => "0円" },
             "shipping_methods" =>
            [{ "id" => 1,
               "code" => "",
               "name" => "ヤマト運輸 - 宅急便",
               "zones" => [{ "id" => 3, "name" => "Japan（北海道・沖縄県 抜き）", "description" => "Japan（北海道・沖縄県 抜き）" }],
               "shipping_categories" => [{ "id" => 1, "name" => "送料込み" }] }],
             "manifest" => [{ "variant_id" => 3, "quantity" => 1, "states" => { "on_hand" => 1 } }],
             "adjustments" =>
            [{ "id" => 2830,
               "source_type" => "Spree::TaxRate",
               "source_id" => 1,
               "adjustable_type" => "Spree::Shipment",
               "adjustable_id" => 1595,
               "amount" => "0.0",
               "label" => "日本（税込） 0.000% (価格に含まれています)",
               "promotion_code_id" => nil,
               "finalized" => true,
               "eligible" => true,
               "created_at" => "2023-12-13T23:22:22.367+09:00",
               "updated_at" => "2023-12-13T23:25:30.767+09:00",
               "display_amount" => "0円" }] }],
        adjustments: [],
        permissions: { "can_update" => true },
        credit_cards: []
      }.to_json
    end
    created_at { FFaker::Time.between(order_time, Time.current) }
    updated_at { FFaker::Time.between(created_at, Time.current) }
    stat_id { nil }
  end
end
