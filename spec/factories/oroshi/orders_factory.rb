FactoryBot.define do
  factory :oroshi_order, class: Oroshi::Order do
    buyer { Oroshi::Buyer.first || create(:oroshi_buyer) }
    product_variation { Oroshi::ProductVariation.first || create(:oroshi_product_variation) }
    shipping_receptacle { Oroshi::ShippingReceptacle.first || create(:oroshi_shipping_receptacle) }
    shipping_method { Oroshi::ShippingMethod.first || create(:oroshi_shipping_method) }
    shipping_date { Time.zone.today }
    arrival_date { Time.zone.today + 1.day }
    item_quantity { 20 }
    receptacle_quantity { 1 }
    freight_quantity { 1 }
    shipping_cost { 100.0 }
    materials_cost { 100.0 }
    sale_price_per_item { 100.0 }
    adjustment { 100.0 }
    note { FFaker::LoremJA.sentence }
    status { Oroshi::Order.statuses.keys.sample }
  end
end
