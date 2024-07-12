FactoryBot.define do
  factory :oroshi_production_request, class: 'Oroshi::ProductionRequest' do
    request_quantity { rand(1..100) }
    fulfilled_quantity { rand(1..100) }
    status { Oroshi::ProductionRequest.statuses.keys.sample }
    product_variation do
      if Oroshi::ProductVariation.count.zero?
        create(:oroshi_product_variation)
      else
        Oroshi::ProductVariation.order('RANDOM()').first
      end
    end
    production_zone do
      if Oroshi::ProductionZone.count.zero?
        create(:oroshi_production_zone)
      else
        Oroshi::ProductionZone.order('RANDOM()').first
      end
    end
    shipping_receptacle do
      if Oroshi::ShippingReceptacle.count.zero?
        create(:oroshi_shipping_receptacle)
      else
        Oroshi::ShippingReceptacle.order('RANDOM()').first
      end
    end
  end
end
