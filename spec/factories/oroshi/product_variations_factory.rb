FactoryBot.define do
  factory :oroshi_product_variation, class: 'Oroshi::ProductVariation' do
    product { Oroshi::Product.last || create(:oroshi_product) }
    default_shipping_receptacle { Oroshi::ShippingReceptacle.last || create(:oroshi_shipping_receptacle) }
    name { FFaker::LoremJA.words(2).join }
    sequence(:handle) { |n| "#{FFaker::Lorem.word}_#{n}" }
    primary_content_volume { rand(1.0..100.0).round(2) }
    primary_content_country_id { '392' } # Japan's ISO numeric_code
    primary_content_subregion_id { rand(1..47) } # Japan has 47 subregions
    shelf_life { rand(1..365) }
    active { true }

    after(:create) do |product_variation|
      # Create associated records
      create_list(:oroshi_packaging, rand(1..2), product_variations: [product_variation])
      create_list(:oroshi_production_zone, rand(1..3), product_variations: [product_variation])
      create_list(:oroshi_supply_type_variation, rand(1..3), product_variations: [product_variation])
      create_list(:oroshi_production_request, rand(1..3), product_variation: product_variation)

      # Attach an image from a URL
      product_variation.image.attach(
        io: URI.open('https://placehold.co/600x400'),
        filename: 'placeholder.png',
        content_type: 'image/png'
      )
    end
  end
end
