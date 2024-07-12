FactoryBot.define do
  factory :oroshi_shipping_receptacle, class: 'Oroshi::ShippingReceptacle' do
    name { FFaker::LoremJA.word + %W[\u7BB1 \u6A3D].sample }
    sequence(:handle) { |n| "#{FFaker::Lorem.word}_#{n}" }
    cost { rand(1.0..100.0).round(2) }
    default_freight_bundle_quantity { rand(1..10) }
    interior_height { rand(1.0..100.0).round(2) }
    interior_width { rand(1.0..100.0).round(2) }
    interior_depth { rand(1.0..100.0).round(2) }
    exterior_height { rand(1.0..100.0).round(2) }
    exterior_width { rand(1.0..100.0).round(2) }
    exterior_depth { rand(1.0..100.0).round(2) }
    active { true }

    after(:create) do |shipping_receptacle|
      # Attach an image from a URL
      shipping_receptacle.image.attach(
        io: URI.open('https://placehold.co/600x400'),
        filename: 'placeholder.png',
        content_type: 'image/png'
      )
    end

    trait :with_production_requests do
      after(:create) do |shipping_receptacle|
        create_list(:oroshi_production_request, rand(1..3), shipping_receptacle: shipping_receptacle)
      end
    end

    trait :with_orders do
      after(:create) do |shipping_receptacle|
        create_list(:oroshi_order, rand(1..3), shipping_receptacle: shipping_receptacle)
      end
    end
  end
end
