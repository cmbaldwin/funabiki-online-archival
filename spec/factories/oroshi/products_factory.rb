FactoryBot.define do
  factory :oroshi_product, class: 'Oroshi::Product' do
    name { FFaker::LoremJA.words(2).join }
    units { %w[kg 個].sample }
    exterior_height { rand(1.0..100.0).round(2) }
    exterior_width { rand(1.0..100.0).round(2) }
    exterior_depth { rand(1.0..100.0).round(2) }
    active { true }
    supply_type { Oroshi::SupplyType.order('RANDOM()').first || create(:oroshi_supply_type) }

    trait :with_materials do
      after(:create) do |product|
        create_list(:oroshi_material, 3, products: [product])
      end
    end

    trait :with_product_variations do
      after(:create) do |product|
        create_list(:oroshi_product_variation, 3, product: product)
      end
    end
  end
end
