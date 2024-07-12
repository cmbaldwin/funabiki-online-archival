FactoryBot.define do
  factory :oroshi_production_zone, class: 'Oroshi::ProductionZone' do
    name { FFaker::LoremJA.word }
    active { true }

    trait :with_product_variations do
      after(:create) do |production_zone|
        create_list(:oroshi_product_variation, rand(1..3), production_zones: [production_zone])
      end
    end
  end
end
